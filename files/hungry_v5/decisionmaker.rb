require 'frame'
require 'piece_mover'
require 'priority_queue'
require 'set'
require 'forwardable'

class Decisionmaker
  extend Forwardable

  attr_accessor :map, :network, :player
  attr_reader :interacted_enemies
  def_delegators :@frame, :walls, :borders, :strength_hurdle, :my_pieces,
                          :multiplier

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

    @frame_number = -1
    @interacted_enemies = Set.new [0, @player]
  end

  def next_turn
    network.frame
    @frame_number += 1
    network.log("Game Frame: #{@frame_number}", :debug)

    @frame = Frame.new(player, map, @interacted_enemies)
    @interacted_enemies = @frame.interactable_enemies
    network.log("Frame #{@frame_number}: Walls & battlefronts calculated", :debug)

    flow_weights
    stop_go
    network.log("Frame #{@frame_number}: Weights flowed", :debug)

    @strength_hurdle = @frame.strength_hurdle
    network.log("Frame #{@frame_number}: Strength hurdle  #{@strength_hurdle}", :debug)

    make_decisions(my_pieces.select{|s| s.strength > 0 })
    network.log("Frame #{@frame_number}: Decisions made", :debug)
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
      s.score = s.initial_score * (@frame.walls.include?(s) ? 100 : 1)
      [s.score, rand, s.score, 0, Neighbor.new(s, :still, 0)]
    end

    queue = PriorityQueue.new(boondocks)

    @considered = Set.new
    network.log("Frame #{@frame_number}: Boondocks, considered, and queue initialized", :debug)

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
        next if @frame.walls.include? neighbor
        next if @considered.include? neighbor
        next if neighbor.score == Float::INFINITY # we'll get to it eventually

        if neighbor.friendly?
          # put the neighbor back in the list with a priority based on current score
          distance = next_best_site.distance + 1
          new_place = discount_score(next_best_site.score, distance)
          # put it back in the queue slightly more expensive and at further distance
          queue << [new_place, neighbor.production + rand, next_best_site.score, distance, neighbor]
        elsif neighbor.neutral?
          distance = next_best_site.distance
          new_score = (1 - SMOOTHING)*next_best_site.score + SMOOTHING*neighbor.strength/neighbor.production
          queue << [new_score, -neighbor.production + rand, new_score, distance, neighbor]
        end
      end
    end
    network.log("Frame #{@frame_number}: Weights flowed", :debug)
  end

  def stop_go
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
    network.log("Frame #{@frame_number}: Trees constructed", :debug)

    trees.each do |root, branches|
      network.log("Frame #{@frame_number}: root - #{root}", :debug)
      builtup_production = 0
      builtup_strength = 0
      walk_tree(branches).each do |level, sites|
        network.log("Frame #{@frame_number}: level - #{level} ---- #{sites.map(&:location)}", :debug)
        if builtup_strength + builtup_production > root.strength
          network.log("Frame #{@frame_number}: previous levels can capture! break the loop!", :debug)
          break
        end
        level_strength = sites.map(&:strength).reduce(:+)
        level_production = sites.map(&:production).reduce(:+)
        network.log("Frame #{@frame_number}: level strength: #{level_strength}   production: #{level_production}", :debug)
        if level_strength + builtup_strength + builtup_production > root.strength
          sorted = sites.sort_by(&:strength)
          while (level_strength + builtup_production + builtup_strength - sorted[0].strength) > root.strength
            level_strength -= sorted.shift.strength
          end
          sorted.map(&:greenlight!)
          network.log("Frame #{@frame_number}: greenlight! #{sorted.map(&:location)}", :debug)
          break
        else
          builtup_strength += level_strength + builtup_production
          builtup_production += level_production
          network.log("Frame #{@frame_number}: redlight!", :debug)
          sites.map(&:redlight!)
        end
      end
    end
    network.log("Frame #{@frame_number}: redlight/greenlight decided", :debug)
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

end
