require 'neighbor'
require 'forwardable'

class PieceMover
  extend Forwardable
  MAX_STRENGTH = 255
  attr_accessor :site, :map, :neighbors

  def_delegators :@site, :owner, :strength, :production, :location,
                         :neutral?, :enemy?, :victim?

  def initialize(site, map, search_distance = 2)
    @site = site
    @map = map
    @neighbors = map.neighbors(location)
    @search_distance = search_distance
  end

  def calculate_move
    if site.is_weak?
      return Move.new(location, :still)
    end

    best_nearby = most_interesting
    if best_nearby
      return Move.new(location, best_nearby)
    end

    Move.new(location, :still)
  end

  def most_interesting
    nearby = map.fetch_nearby(location, @search_distance)
    attackable = nearby.select{|s| s.victim? }

    if attackable.empty?
      return nearest_edge
    end

    group_by_dir   = attackable.group_by(&:direction)
    sums_of_scores = group_by_dir.each_with_object({}) {|(k, v), h| h[k] = v.map(&:interesting).reduce(:+) }
    interestingest_direction = sums_of_scores.max_by(&:last).first

    if interestingest_direction.nil?
      return nearest_edge
    end

    neighbor = neighbors.find{|s| s.direction == interestingest_direction }
    if neighbor.neutral?
      if neighbor.strength == MAX_STRENGTH
        return neighbor.direction
      end
      if neighbor.strength >= strength
        return :still
      end
    end

    # in a warzone!
    if neighbor.enemy? || (neighbor.neutral? && neighbor.strength == 0)
      return most_attackable
    end

    return interestingest_direction
  end

  def most_attackable
    enemies = neighbors.select{|s| s.victim? }
    sorted = enemies.sort{|a,b| heuristic(b) <=> heuristic(a) }

    best_attack = sorted.first
    if !best_attack.nil? && site.strength > best_attack.strength
      return best_attack.direction
    end
    false
  end

  def heuristic(enemy)
    # take over a neutral site
    if enemy.owner == 0 && enemy.strength != 0
      return enemy.production
    end

    totalDamage = [enemy.strength, @site.strength].min;

    GameMap::CARDINALS.shuffle.each do |cardinal|
      sibling = map.site(enemy.location, cardinal);
      if sibling.enemy?
        totalDamage += [sibling.strength, @site.strength].min
      end
    end

    return totalDamage;
  end

  def nearest_edge
    farthest_distance = max_distance
    direction = [:south, :east].shuffle.first

    GameMap::CARDINALS.each do |current_direction|
      vector_length = 0
      pointer = location
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

    direction
  end

  def max_distance
    ([map.width, map.height].max / 1.5).ceil;
  end

end
