require 'piece_mover'
require 'strategizer'

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
    @strategizer = Strategizer.new(@map, @player)
  end

  def next_turn
    network.frame
    @game_stage = nil
    @frame += 1
    network.log("Game Frame #{@frame}, stage: #{game_stage}", :debug)
    @strategizer.make_decisions
  end

  def moves
    map.sites.map(&:moves).flatten
  end

  def search_distance
    SEARCH_DISTANCES[game_stage]
  end

  def game_stage
    @game_stage ||= begin
      neutral = map.sites.select{|v| v.neutral? }
      percent = (neutral.length.to_f/map.sites.length) * 100

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
