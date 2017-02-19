require 'piece_mover'
require 'priority_queue'
require 'set'

class Decisionmaker
  attr_accessor :map, :network, :player, :battlefronts
  attr_reader :interacted_enemies, :walls, :borders, :strength_hurdle, :borders

  # smoothing constant for discounting ROI over distance.
  SMOOTHING = 0.10
  # Times friendly_distance ** 2 is potential degradation.
  POTENTIAL_DEGREDATION = 0.2
  # Amount of ROI to include for each enemy adjacent to an empty square.
  ENEMY_ROI = -0.5
  # hold square STILL until strength >= multiplier * production.
  COMBAT_MULTIPLIER = 7
  BASE_MULTIPLIER = 5
  # Max proportion of interior pieces allowed to move.
  INT_MAX = 0.45
  # Min proportion of interior pieces allowed to move
  INT_MIN = 0.01
  # Enables strategic stilling behavior.
  ENABLE_STRATEGIC_STILLING = true
  # Enables red-green trees for timing mining moves
  ENABLE_RED_GREEN = true


  def initialize(network, player, map)
    @network, @player, @map = network, player, map

    @frame = -1
    @interacted_enemies = Set.new [0, @player]
    @battlefronts = []
    @walls = Set.new
  end

  def next_turn
    network.frame
    @frame += 1
    network.log("Game Frame: #{@frame}", :debug)

    @battlefronts = Set.new(map.sites.select(&:battlefront?))
    @interacted_enemies.merge(battlefronts.map{|s| s.neighbors.map(&:owner) }.flatten)
    @walls = Set.new(map.sites.select{|s| s.being_a_wall?(@interacted_enemies) })
    @strength_hurdle = calculate_strength_hurdle
    @borders = map.sites.select{|s| s.neutral? && s.production > 0 && !@walls.include?(s) && s.neighbors.any?(&:friendly?) }

    network.log("Frame #{@frame}: Walls & battlefronts calculated", :debug)
    network.log("Frame #{@frame}: Strength hurdle  #{@strength_hurdle}", :debug)

    flow_weights
    network.log("Frame #{@frame}: Weights flowed", :debug)
    make_decisions(my_pieces.select{|s| s.strength > 0 })
    network.log("Frame #{@frame}: Decisions made", :debug)
  end

  def moves
    map.sites.map(&:moves).flatten
  end

  def make_decisions(pieces)
    distances = @considered.to_a
    sorted = pieces.sort_by{|s| [-s.strength, distances[distances.find_index(s)].distance ] }
    sorted.each do |site|
      mover = PieceMover.new(site, map, self)
      mover.calculate_move
    end
  end

  def flow_weights
    boondocks = map.sites.select(&:victim?).map do |s|
      s.score = s.initial_score * (@walls.include?(s) ? 100 : 1)
      [s.score, rand, s.score, 0, Neighbor.new(s, :still, 0)]
    end

    queue = PriorityQueue.new(boondocks)

    @considered = Set.new
    network.log("Frame #{@frame}: Boondocks, considered, and queue initialized", :debug)

    while @considered.length < network.size
      n, _, score, distance, next_best_site = queue.pop

      if @considered.include? next_best_site
        next
      end

      next_best_site.score = score
      next_best_site.distance = distance
      next_best_site.discounted_score = discount_score(score, distance)
      @considered << next_best_site

      next_best_site.neighbors.each do |neighbor|
        # skip any neighbors in walls. They shouldn't count toward weighing
        # the value of other squares since we won't path through them.
        next if @walls.include? neighbor
        next if @considered.include? neighbor
        next if neighbor.score == Float::INFINITY # we'll get to it eventually

        if neighbor.friendly?
          # put the neighbor back in the list with a priority based on current score
          distance = next_best_site.distance + 1
          new_place = discount_score(next_best_site.score, distance)
          # put it back in the queue slightly more expensive and at further distance
          queue << [new_place, rand, next_best_site.score, distance, neighbor]
        elsif neighbor.neutral?
          distance = next_best_site.distance
          new_score = (1 - SMOOTHING)*next_best_site.score + SMOOTHING*neighbor.strength/neighbor.production
          queue << [new_score, rand, new_score, distance, neighbor]
        end
      end
    end

    edges = my_pieces.map do |site|
      [ site.neighbors.min_by(&:discounted_score), site ]
    end

    trees = Hash.new{|h, k| h[k] = {}}
    edges.each do |parent, child|
      trees[parent][child] = trees[child]
    end
    parents, children = edges.map(&:first), edges.map(&:last)
    roots = Set.new(parents) - children
    trees = trees.select{|base, branches| roots.include? base }
    network.log("Frame #{@frame}: Trees constructed", :debug)

    trees.each do |root, branches|
      builtup_production = 0
      builtup_strength = 0
      walk_tree(branches).each do |level, sites|
        if builtup_strength + builtup_production > root.strength
          break
        end
        level_strength = sites.map(&:strength).reduce(:+)
        level_production = sites.map(&:production).reduce(:+)
        if level_strength + builtup_strength + builtup_production > root.strength
          sorted = sites.sort_by(&:strength)
          while (level_strength + builtup_production + builtup_strength - sorted[0].strength) > root.strength
            level_strength -= sorted.shift.strength
          end
          sorted.map(&:greenlight!)
          break
        else
          builtup_strength += level_strength + builtup_production
          builtup_production += level_production
          sites.map(&:redlight!)
        end
      end
    end
    network.log("Frame #{@frame}: redlight/greenlight decided", :debug)

    # if @borders.empty?
    #   my_pieces.each{|s| s.flow_direction = :still }
    #   return
    # end

    # queue = @borders.sort_by{|s| s.score }
    # while site = queue.shift
    #   site.neighbors.each do |neighbor|
    #     next unless neighbor.friendly?
    #     score = site.score - neighbor.production - 2
    #     if neighbor.score.nil? || score > neighbor.score
    #       neighbor.score = score
    #       neighbor.flow_direction = @map.reverse_direction(neighbor.direction)
    #       queue << neighbor
    #     end
    #   end
    # end
  end

  def walk_tree(branches, level=1)
    if branches.empty?
      return {}
    end
    twigs = walk_tree(branches.values.reduce({}, :merge), level+1)
    { level => Set.new(branches.keys) }.merge(twigs)
  end

  def discount_score(score, distance)
    return score + POTENTIAL_DEGREDATION * distance**2
  end

  def my_pieces
    map.sites.select{|s| s.friendly? }
  end

  def multiplier
    battlefronts.length > 0 ? COMBAT_MULTIPLIER : BASE_MULTIPLIER
  end

  def calculate_strength_hurdle
    strengths = my_pieces.select{|s| s.neighbors.all?(&:friendly?) }.map(&:strength).sort.reverse
    return 0 if strengths.empty?
    percent = (1 - strengths.length.to_f/network.size) * (INT_MAX - INT_MIN) + INT_MIN
    strengths[(strengths.length*percent).to_i]
  end

end
