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
  end

  def next_turn
    network.frame
    @game_stage = nil
    make_decisions
  end

  def moves
    map.sites.map(&:moves).flatten
  end

  def make_decisions
    my_peices.sort_by{|s| -s.strength }.each do |site|
      mover = PieceMover.new(site, map)
      mover.calculate_move(search_distance)
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
