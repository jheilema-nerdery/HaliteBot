require 'piece_mover'
require 'priority_queue'
require 'set'

class Decisionmaker
  attr_accessor :map, :network, :player
  EARLY = 80
  LATE = 20

  SEARCH_DISTANCES = {
    early: 6,
    mid:   4,
    late:  3
  }

  def initialize(network, player, map)
    @network, @player, @map = network, player, map

    @game_stage = :early
    @frame = 0
  end

  def next_turn
    network.frame
    @game_stage = nil
    @frame += 1
    @borders = nil
    network.log("Game Frame #{@frame}, stage: #{game_stage}", :debug)
    flow_weights
    make_decisions(my_pieces)
  end

  def moves
    map.sites.map(&:moves).flatten
  end

  def make_decisions(pieces)
    sorted = pieces.sort_by{|s| -s.score }
    sorted.each do |site|
      mover = PieceMover.new(site, map, multiplier, search_distance)
      mover.calculate_move
    end
  end

  def flow_weights
    borders.each do |site|
      scoreable = @map.fetch_nearby(site.location, 3).group_by(&:direction)
      best_direction_score = scoreable.map do |direction, sites|
        sites.map{|n| (site.production == 0 || site.enemy? ? 255.0 : (site.strength + 1).to_f/site.production) + 0.2*n.distance**2 }.reduce(:+)
      end.min
      base_score = site.production == 0 ? 255.0 : (site.strength + 1).to_f/site.production
      site.score = base_score + best_direction_score
      @network.log("#{site} score: #{site.score}")
    end

    queue = PriorityQueue.new(borders.map{|s| [s.score, rand, 0, s] })
    visited = Set.new
    friendly_count = my_pieces.length
    while visited.length < friendly_count
      score, _, distance, site = queue.pop

      @network.log("Visiting #{site}, score: #{site.score}")
      if site.friendly?
        site.flow_direction = @map.reverse_direction(site.direction)
        site.score = score
        visited << site
      end

      site.neighbors.each do |dir, neighbor|
        next unless neighbor.friendly?
        next if visited.include? neighbor
        score = (site.score + neighbor.production**1.5) + 0.2*distance**2
        queue << [score, rand, distance+1, neighbor]
      end
    end
    visited.each do |site|
      @network.log("#{site} dir: #{site.flow_direction} score: #{site.score}")
    end
  end

  def my_pieces
    map.sites.select{|s| s.friendly? }
  end

  def borders
    @borders ||= map.sites.select{|v| v.neutral? && v.neighbors.values.any?(&:friendly?) }
  end

  def multiplier
    case game_stage
    when :early
      5
    when :late
      9
    else
      6
    end
  end

  def search_distance
    SEARCH_DISTANCES[game_stage]
  end

  def game_stage
    @game_stage ||= begin
      neutral = map.sites.select{|v| v.neutral? }
      percent = (neutral.length.to_f/map.sites.length) * 100

      network.log("Neutral sites: #{neutral.length}, #{percent}%", :debug)
      network.log("Uncontested Neutral: #{neutral.select{|v| v.strength > 0 }.length}, #{(neutral.select{|v| v.strength > 0 }.length.to_f/map.sites.length) * 100}%", :debug)

      if percent > EARLY
        :early
      elsif percent < LATE
        :late
      else
        :mid
      end
    end
  end

end
