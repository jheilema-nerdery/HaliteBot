class Decisionmaker
  attr_accessor :map

  def initialize(network)
    @network = network
    @map = network.map
    @max_distance = ([map.width, map.height].max / 2).ceil;
    @direction = :north
    @counter = 0
  end

  def rotate_direction
    @counter += 1
    @counter = 0 if @counter >= 4
    @direction = GameMap::CARDINALS[@counter]
  end

  def move(site, location)
    @neighbors = nil
    @location = location
    @site = site

    if is_weak?
      return Move.new(@location, :still)
    end

    if are_allies?(neighbors)
      return move_to_nearest_edge
    end

    enemies = neighbors.select{|dir, s| s.owner != @site.owner }.to_a
    sorted = enemies.sort{|a,b| heuristic(b) <=> heuristic(a) }
    best_attack = sorted.first
    if !best_attack.nil? && @site.strength > best_attack[1].strength
      return Move.new(location, best_attack[0])
    end

    Move.new(location, :still)
  end

  def move_to_nearest_edge
    farthest_distance = @max_distance
    direction = @direction

    GameMap::CARDINALS.shuffle.each do |current_direction|
      vector_length = 0
      pointer = @location
      next_site = map.site(pointer, current_direction);
      while (next_site.owner == @site.owner && vector_length < farthest_distance) do
        vector_length += 1
        pointer = map.find_location(pointer, current_direction);
        next_site = map.site(pointer, current_direction);
      end

      if (vector_length < farthest_distance)
        direction = current_direction
        farthest_distance = vector_length
      end
    end

    Move.new(@location, direction)
  end

  def heuristic(enemy_data)
    direction = enemy_data[0]
    enemy = enemy_data[1]

    # take over a neutral site
    if enemy.owner == 0 && enemy.strength != 0
      return enemy.production
    end

    # attack an enemy
    totalDamage = enemy.strength;
    location = map.find_location(@location, direction)

    GameMap::CARDINALS.shuffle.each do |cardinal|
      sibling = map.site(location, cardinal);
      if (sibling.owner != 0 && sibling.owner != @site.owner)
        totalDamage += sibling.strength
      end
    end

    return totalDamage;
  end

  def are_allies?(neighbors)
    neighbors.values.all?{|s| s.owner == @site.owner }
  end

  def alone?
    neighbors.values.none?{|s| s.owner == @site.owner }
  end

  def is_weak?
    @site.strength < 5 || (@site.strength < 5 * @site.production)
  end

  def neighbors
    @neighbors ||= map.neighbors(@location)
  end

end
