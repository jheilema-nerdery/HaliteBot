require 'piece_mover'

class Decisionmaker
  attr_accessor :map, :network, :player
  EARLY = 80
  LATE = 20

  SEARCH_DISTANCES = {
    early: 5,
    mid:   6,
    late:  5
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
    network.log("Game Frame #{@frame}, stage: #{game_stage}", :debug)
    make_decisions
  end

  def moves
    map.sites.map(&:moves).flatten
  end

  def make_decisions
    my_peices.sort_by{|s| -s.strength }.each do |site|
      mover = PieceMover.new(site, map, game_stage, search_distance)
      mover.calculate_move
    end
  end

  def my_peices
    map.sites.select{|s| s.owner == @player }
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
