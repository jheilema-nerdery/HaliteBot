require 'neighbor'
require 'forwardable'

class PieceMover
  extend Forwardable
  attr_accessor :site, :map

  def_delegators :@site, :location

  def initialize(site, map, decisionmaker)
    @site = site
    @map = map
    @decisionmaker = decisionmaker
    @multiplier = @decisionmaker.multiplier
    @interacted_enemies = @decisionmaker.interacted_enemies
    @strength_hurdle = decisionmaker.strength_hurdle
  end

  def calculate_move
    score, _, best_direction, target = sorted_directions.first
    if site.greenlight
      Networking.log("#{site.location} Greenlight", :debug)
      return site.add_move(best_direction)
    end

    if stillness_allowed && (site.planned_strength > 0 || site.redlight)
      Networking.log("#{site.location} planned strength > 0 || redlight", :debug)
      return site.add_move(:still)
    end

    dangerous_neighbors = map.fetch_nearby(location, distance = 2).uniq.select(&:dangerous?).map do |neighbor|
      [neighbor, [255, neighbor.self_with_neighbors.select(&:enemy?).map(&:strength).reduce(:+)].min]
    end.to_h

    if stillness_allowed && dangerous_neighbors.length == 0 &&
        site.neighbors.select(&:blank_neutral?).length > 1 &&
        site.neighbors.map(&:neighbors).flatten.uniq.select{|n2| n2.enemy? && n2.strength >= 3*n2.production }.length > 1
      Networking.log("#{site.location} strategic still", :debug)
      return site.add_move(:still)
    end

    if target.self_with_neighbors.any?{|n| dangerous_neighbors.include?(n) } ||
      (site.is_weak?(@multiplier) && site.neighbors.any?{|n| dangerous_neighbors.include?(n) })
      best_direction_neighbor = site.self_with_neighbors.min_by do |neighbor|
          neighbor.discounted_score \
        + (10_000 * [0, (neighbor.planned_strength + @site.strength - 255)].max) \
        + (neighbor.planned_strength == 0 ? neighbor.self_with_neighbors.map{|n2| dangerous_neighbors[n2] || 0 }.reduce(:+) * 5_000 : 0)
        + (neighbor.being_a_wall?(@interacted_enemies) ? 1_000_000 : 0) \
        + (neighbor.neutral? && site.strength <= neighbor.strength ? 100_000 : 0)
      end
      Networking.log("#{site.location} best direction neighbor, #{best_direction_neighbor.discounted_score}", :debug)
      return site.add_move(best_direction_neighbor.direction)
    end

    if !stillness_allowed || score > 9_000
      stay_here  = [255, site.strength + site.production + site.planned_strength].min + [255, target.planned_strength].min
      move_there = [255, site.planned_strength].min + [255, target.planned_strength + site.strength].min
      if stay_here > move_there
        Networking.log("#{site.location} stay here, at a loss", :debug)
        return site.add_move(:still)
      else
        Networking.log("#{site.location} move there, at a loss", :debug)
        return site.add_move(best_direction)
      end
    end

    if target.victim?
      if (site.at_max? || site.strength + target.planned_strength > target.strength) &&
          site.strength >= 2 * site.production &&
          (target.planned_strength == 0 || !site.is_weak?(@multiplier))
        Networking.log("#{site.location} best direction target. #{site}, #{target}", :debug)
        return site.add_move(best_direction)
      end
    elsif site.strength >= [@strength_hurdle, @multiplier * site.production].max
      Networking.log("#{site.location} strength hurdle, multiplier overcome. [#{@strength_hurdle}, #{@multiplier*site.production}], strength: #{site.strength}", :debug)
      return site.add_move(best_direction)
    end

    Networking.log("#{site.location} nothing matched, stay still!", :debug)
    site.add_move(:still)
  end

  def most_interesting(attackable)
    # Get a hash of attackable objects grouped by the direction they're in
    group_by_dir = attackable.group_by(&:direction)

    # Sum the values of all the sites interestingness. Again, group by direction.
    sums = {}
    group_by_dir.map do |direction, sites|
      sums[direction] = sites.map(&:interesting_per_distance).reduce(:+)
    end

    # convert to an array of arrays, sort by the second value
    # in the array, then return the first values (the direction!)
    # Reversed so the first is the most interesting direction, last is the least
    sorted_directions = sums.sort_by(&:last).map(&:first).reverse

    return handle_special_cases(sorted_directions)
  end

  def handle_special_cases(sorted_directions)
    # get the first element off the array - changes the array!
    interestingest_direction = sorted_directions.shift
    neighbor = @site.neighbor(interestingest_direction)

    # no more interesting directions found
    if interestingest_direction.nil?
      return :still
    end

    if neighbor.neutral?
      # attack things that otherwise don't get attacked
      if neighbor.at_max?
        return interestingest_direction
      end
      if neighbor.strength >= @site.strength && stillness_allowed
        return :still
      end
      # go in a different direction
      if neighbor.being_a_wall?
        return :still if stillness_allowed
        return handle_special_cases(sorted_directions)
      end
    end

    return interestingest_direction
  end

  def most_attackable
    sorted = allowed_directions.map{|dir| @site.neighbor(dir) }.select{|s| s.blank_neutral? || s.friendly? }
      .sort_by{|site| [-attack_heuristic(site), -site.interesting] }
    best = sorted.first

    return :still if best.nil?
    return :still if best.neutral? && @site.strength < best.strength && stillness_allowed

    best.direction
  end

  def attack_heuristic(target)
    damage = 0

    # prefer attacking then wasting energy on neutral blocks.
    # if the neutral block is contested, this will be zero and won't matter.
    if target.neutral?
      damage -= target.strength/2
    end

    # assume far away enemies will come forward
    buffer = target.neighbor(target.direction)
    if buffer.neutral? && buffer.neighbor(target.direction).enemy?
      damage += [buffer.neighbor(target.direction).strength, @site.strength].min
    end

    target.neighbors.select(&:enemy?).each do |sibling|
      damage += [sibling.strength, @site.strength].min
    end

    return damage
  end

  def nearest_edge
    farthest_distance = max_distance
    direction = [:south, :east].shuffle.first
    sorted = allowed_directions.sort_by{|dir| @site.neighbor(dir).production }

    sorted.each do |current_direction|
      vector_length = 0
      next_site = @site.neighbor(current_direction)

      while (next_site.owner == @site.owner && vector_length < farthest_distance) do
        vector_length += 1
        next_site = next_site.neighbor(current_direction)
      end

      if (vector_length < farthest_distance)
        direction = current_direction
        farthest_distance = vector_length
      end
    end

    direction
  end

  def max_distance
    ([map.width, map.height].max / 1.5).ceil;
  end

  def stillness_allowed
    if defined?(@stillness_allowed)
      return @stillness_allowed
    end

    @stillness_allowed = !@site.overflowing?
  end

  def allowed_directions
    @allowed_directions ||= GameMap::CARDINALS.select do |dir|
      !@site.neighbor(dir).proposed_strength_too_big?(@site.strength)
    end
  end

  def sorted_directions
    @sorted_directions ||= site.neighbors.map do |neighbor|
      score = neighbor.discounted_score +
              (10_000 * [0, (neighbor.planned_strength + @site.strength - 255)].max) +
              (@decisionmaker.borders.length > 0 && neighbor.being_a_wall?(@interacted_enemies) ? 1_000_000 : 0 )
      [score, rand, neighbor.direction, neighbor]
    end.sort
  end

end
