require 'neighbor'

class Decisionmaker
  attr_accessor :map, :moves

  def initialize(network)
    @network = network
    @map = network.map
    @max_distance = ([map.width, map.height].max / 1.5).ceil;
    @direction = :north
    @counter = 0
    @moves = []
    identify_interesting_locations
  end

  def rotate_direction
    @counter += 1
    @counter = 0 if @counter >= 4
    @direction = GameMap::CARDINALS[@counter]
  end

  def reset_moves
    @moves = []
  end

  def move(site)
    @moves << calculate_move(site)
  end

  private

  def identify_interesting_locations
    map
  end

  def calculate_move(site)
    @neighbors = nil
    @site = site

    if @site.is_weak?
      return Move.new(@site.location, :still)
    end

    if are_allies?(neighbors)
      return move_to_nearest_edge
    end

    enemies = neighbors.select{|s| s.owner != @site.owner }
    sorted = enemies.sort{|a,b| heuristic(b) <=> heuristic(a) }

    best_attack = sorted.first
    if !best_attack.nil? && @site.strength > best_attack.strength
      return Move.new(@site.location, best_attack.direction)
    end

    Move.new(@site.location, :still)
  end

  def move_to_nearest_edge
    farthest_distance = @max_distance
    direction = @direction

    GameMap::CARDINALS.shuffle.each do |current_direction|
      vector_length = 0
      pointer = @site.location
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

    Move.new(@site.location, direction)
  end

  def heuristic(enemy)
    # take over a neutral site
    if enemy.owner == 0 && enemy.strength != 0
      return enemy.production
    end

    totalDamage = enemy.strength;

    GameMap::CARDINALS.shuffle.each do |cardinal|
      sibling = map.site(enemy.location, cardinal);
      if (sibling.owner != 0 && sibling.owner != @site.owner)
        totalDamage += sibling.strength
      end
    end

    return totalDamage;
  end

  def are_allies?(neighbors)
    neighbors.all?{|s| s.owner == @site.owner }
  end

  def neighbors
    @neighbors ||= map.neighbors(@site.location)
  end

end
