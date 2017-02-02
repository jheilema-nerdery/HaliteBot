require 'piece_mover'

class Decisionmaker
  attr_accessor :map, :moves, :network, :player
  EARLY = 70
  LATE = 20

  SEARCH_DISTANCES = {
    early: 4,
    mid:   5,
    late:  5
  }

  def initialize(network, player, map)
    @network, @player, @map = network, player, map

    @game_stage = :early
    @moves = []
  end

  def reset_turn
    @moves = []
    @game_stage = nil
  end

  def make_decisions
    mine = map.content.values.select{|s| s.owner == @player }
    mine.each do |site|
      move(site)
    end
  end

  def move(site)
    mover = PieceMover.new(site, map, search_distance)
    @moves << mover.calculate_move
  end

  def search_distance
    SEARCH_DISTANCES[game_stage]
  end

  def game_stage
    @game_stage ||= begin
      num_neutral = map.content.values.select{|v| v.neutral? }
      percent     = (num_neutral.length.to_f/map.content.length) * 100
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
