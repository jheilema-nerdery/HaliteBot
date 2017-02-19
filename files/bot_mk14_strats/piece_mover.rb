require 'neighbor'
require 'forwardable'

class PieceMover
  extend Forwardable
  attr_accessor :site, :map, :search_distance

  def_delegators :@site, :location

  def initialize(site, map, game_stage, search_distance)
    @site = site
    @map = map
    @game_stage = game_stage
    @search_distance = search_distance
  end

  def calculate_move
    if site.strength == 0 || (site.is_weak? && stillness_allowed)
      return site.add_move(:still)
    end

    if @site.in_a_warzone?
      return site.add_move most_attackable
    end

    if @site.neighbors.values.any?(&:being_a_wall?)
      return @site.add_move(:still)
    end
    expand
  end

  def expand
    nearby = map.fetch_nearby(location, search_distance, allowed_directions)

    if nearby.none?(&:victim?)
      return site.add_move(nearest_edge)
    end

    site.add_move(most_interesting(nearby))
  end

  def move_towards(location, expanding = false)
    directions = map.angle_between(site.location, location)
    Networking.log("Move #{site} towards #{location}, directions: #{directions}")
    possible = allowed_directions & directions

    if possible.empty?
      if stillness_allowed || allowed_directions.length == 0
        site.add_move(:still)
      else
        site.add_move(allowed_directions.shuffle.first)
      end
      return 0
    end

    neighbors = site.neighbors.values.select{|n| possible.include?(n.direction) }

    battlefront = neighbors.select(&:battlefront?)
    if !battlefront.empty?
      site.add_move(battlefront.first.direction)
      return site.strength
    end

    friendly = neighbors.select(&:friendly?)
    if !friendly.empty?
      site.add_move(friendly.first.direction)
      return site.strength
    end

    neutral = neighbors.select{|n| n.neutral? && n.strength < site.strength }
    if expanding && !neutral.empty?
      site.add_move(neutral.shuffle.first.direction)
      return 0
    end

    if stillness_allowed || allowed_directions.length == 0
      site.add_move(:still)
      return 0
    end

    site.add_move(allowed_directions.shuffle.first)
    return 0
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
    neighbor = @site.neighbors[interestingest_direction]

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
    sorted = allowed_directions.map{|dir| @site.neighbors[dir] }.select{|s| (s.neutral? && s.strength == 0) || s.friendly? }
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
    buffer = target.neighbors[target.direction]
    if buffer.neutral? && buffer.neighbors[target.direction].enemy?
      damage += [buffer.neighbors[target.direction].strength, @site.strength].min
    end

    target.neighbors.values.select(&:enemy?).each do |sibling|
      damage += [sibling.strength, @site.strength].min
    end

    return damage
  end

  def nearest_edge
    farthest_distance = max_distance
    direction = [:south, :east].shuffle.first
    sorted = allowed_directions.sort_by{|dir| @site.neighbors[dir].production }

    sorted.each do |current_direction|
      vector_length = 0
      next_site = @site.neighbors[current_direction]

      while (next_site.owner == @site.owner && vector_length < farthest_distance) do
        vector_length += 1
        next_site = next_site.neighbors[current_direction]
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
      !@site.neighbors[dir].proposed_strength_too_big?(@site.strength)
    end
  end

end
