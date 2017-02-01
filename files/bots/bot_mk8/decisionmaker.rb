require 'neighbor'

class Decisionmaker
  attr_accessor :map, :moves, :network

  def initialize(network)
    @network = network
    @map = network.map
    @owners = map.owners
    @max_distance = ([map.width, map.height].max / @owners).ceil;
    @direction = :north
    @counter = 0
    @moves = []
  end

  def rotate_direction
    @counter += 1
    @counter = 0 if @counter >= 4
    @direction = GameMap::CARDINALS[@counter]
  end

  def reset_turn
    @moves = []
  end

  def move(site)
    @moves << calculate_move(site)
  end

  private

  def calculate_move(site)
    @neighbors = map.neighbors(site.location)
    @site = site

    if @site.is_weak?
      return Move.new(@site.location, :still)
    end

    nearby = map.fetch_nearby(@site.location, 3)
    if nearby.all?{|s| s.owner == 0 || s.owner == @site.owner }
      return move_to_most_interesting(nearby)
    end

    enemies = @neighbors.select{|s| s.owner != @site.owner }
    sorted = enemies.sort{|a,b| heuristic(b) <=> heuristic(a) }

    best_attack = sorted.first
    if !best_attack.nil? && @site.strength > best_attack.strength
      return Move.new(@site.location, best_attack.direction)
    end

    Move.new(@site.location, :still)
  end

  def move_to_most_interesting(nearby)
    neutral        = nearby.select{|s| s.neutral? }

    if neutral.empty?
      return move_to_nearest_edge
    end

    group_by_dir   = neutral.group_by(&:direction)
    @network.log(group_by_dir, :debug)
    sums_of_scores = group_by_dir.each_with_object({}) {|(k, v), h| h[k] = v.map(&:interesting).reduce(:+) }
    @network.log(sums_of_scores, :debug)
    interestingest_direction = sums_of_scores.max_by(&:last).first
    @network.log(interestingest_direction, :debug)

    if interestingest_direction.nil?
      return move_to_nearest_edge
    end

    neighbor = @neighbors.find{|s| s.direction == interestingest_direction }
    if neighbor.neutral? && neighbor.strength >= @site.strength
      return Move.new(@site.location, :still)
    end

    return Move.new(@site.location, interestingest_direction)
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

end
