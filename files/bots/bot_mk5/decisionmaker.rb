class Decisionmaker
  attr_accessor :map

  def initialize(network)
    @network = network
    @map = network.map
    @max_distance = ([map.width, map.height].min / 2).floor;
  end

  def move(site, location)
    if !is_strong?(site)
      return Move.new(location, :still)
    end

    neighbors = neighbors(location)

    if are_allies?(neighbors, site)
      return move_to_nearest_edge(site, location)
    end

    enemies = neighbors.select{|dir, s| s.owner != site.owner }.to_a

    if enemies.length >= 3
      sorted = enemies.sort{|a,b| a[1].strength <=> b[1].strength }
      weakest = sorted.first
      if !weakest.nil? && site.strength > weakest[1].strength
        return Move.new(location, weakest[0])
      end
    end

    friends = neighbors.select{|dir, s| s.owner == site.owner }.to_a
    bigger = friends.select{|dir, s| s.strength > site.strength }
    if bigger.length > 0
      sorted = bigger.sort{|a,b| a[1].strength <=> b[1].strength }
      return Move.new(location, sorted.last[0])
    end

    sorted = enemies.sort{|a,b| b[1].production <=> a[1].production }
    best_production = sorted.first

    if !best_production.nil? && site.strength > best_production[1].strength
      return Move.new(location, best_production[0])
    end

    Move.new(location, :still)
  end

  def move_to_nearest_edge(site, location)
    farthest_distance = @max_distance
    direction = :north

    GameMap::CARDINALS.shuffle.each do |current_direction|
      vector_length = 0
      pointer = location
      next_site = map.site(pointer, current_direction);
      while (next_site.owner == site.owner && vector_length < farthest_distance) do
        vector_length += 1
        pointer = map.find_location(pointer, current_direction);
        next_site = map.site(pointer, current_direction);
      end

      if (vector_length < farthest_distance)
          direction = current_direction
          farthest_distance = vector_length
      end
    end

    Move.new(location, direction)
  end

  def are_allies?(neighbors, site)
    neighbors.values.all?{|s| s.owner == site.owner }
  end

  def alone?(neighbors, site)
    neighbors.values.none?{|s| s.owner == site.owner }
  end

  def is_weak?(site)
    site.strength < 5 || (site.strength < 5 * site.production)
  end

  def is_strong?(site)
    site.strength > 3 && (site.strength >= 5 * site.production)
  end

  def neighbors(location)
    map.neighbors(location)
  end

end
