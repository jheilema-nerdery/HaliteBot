require 'piece_mover'

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
      if site.neighbors.values.select(&:friendly?).length > 1
        site.score = site.production * 5 - (site.strength * 0.4)
      else
        friendly = site.neighbors.values.find(&:friendly?)
        direction_to_score = @map.reverse_direction(friendly.direction)
        scoreable = @map.fetch_nearby(friendly.location, 4, [direction_to_score])
        site.score = site.production * 5 - (site.strength * 0.4) + scoreable.map{|n| n.friendly? ? -n.production : (n.production*5 - (n.strength*0.4))/(n.distance+1) }.reduce(&:+)
      end
      @network.log("#{site} score: #{site.score}")
    end

    queue = borders.sort_by{|s| -s.score }
    while site = queue.shift
      site.neighbors.each do |dir, neighbor|
        next unless neighbor.friendly?
        score = site.score - neighbor.production - 2
        if neighbor.score.nil? || score > neighbor.score
          neighbor.score = score
          neighbor.flow_direction = @map.reverse_direction(dir)
          queue << neighbor
        end
      end
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
