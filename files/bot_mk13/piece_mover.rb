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

  def calculate_move
    if site.strength == 0 || (site.is_weak? && stillness_allowed)
      return site.add_move(:still)
    end

    attackable = map.fetch_nearby(location, search_distance, allowed_directions).select{|s| s.victim? }

    if attackable.empty?
      return site.add_move(nearest_edge)
    end

    site.add_move(most_interesting(attackable))
  end

  def most_interesting(attackable)
    if @site.in_a_warzone?
      return most_attackable
    end

    interestingest_direction = interesting(attackable)
    neighbor = @site.neighbors[interestingest_direction]

    if neighbor.neutral?
      if neighbor.at_max?
        return interestingest_direction
      end
      if neighbor.strength >= @site.strength && stillness_allowed
        return :still
      end
      if neighbor.being_a_wall?
        return :still
      end
    end

    return interestingest_direction
  end

  def most_attackable
    allowed_neighbors = allowed_directions.map{|dir| @site.neighbors[dir] }
    nearby = allowed_neighbors.select{|s| s.victim? }
    sorted = nearby.sort_by{|site| [attack_heuristic(site), site.interesting] }
    best = sorted.last

    return :still if best.nil?
    return :still if best.neutral? && @site.strength < best.strength && stillness_allowed

    best.direction
  end

  def interesting(attackable)
    # Get a hash of attackable objects grouped by the direction they're in
    group_by_dir = attackable.group_by(&:direction)

    # Sum the values of all the sites interestingness. Again, group by direction.
    sums = {}
    group_by_dir.map do |direction, sites|
      sums[direction] = sites.map(&:interesting_per_distance).reduce(:+)
    end

    # convert to an array of arrays, select the maximum by the second value
    # in the array, then return the first value (the direction!)
    sums.max_by(&:last).first
  end

  def attack_heuristic(neighbor)
    damage = 0

    # prefer attacking then wasting energy on neutral blocks.
    # if the neutral block is on the battlefront, it'll be zero and
    # this won't matter.
    if neighbor.neutral?
      damage -= neighbor.strength/2
    end

    if neighbor.enemy?
      damage += [neighbor.strength, @site.strength].min
    end

    neighbor.neighbors.values.select(&:enemy?).each do |sibling|
      damage += [sibling.strength, @site.strength].min
    end

    return damage
  end

  def nearest_edge
    farthest_distance = max_distance
    direction = [:south, :east].shuffle.first

    allowed_directions.shuffle.each do |current_direction|
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

end
