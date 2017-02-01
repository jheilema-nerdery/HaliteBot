require 'piece_mover'

class Decisionmaker
  attr_accessor :map, :moves, :network
  EARLY = 60
  LATE = 20

  SEARCH_DISTANCES = {
    early: 6,
    mid:   4,
    late:  2
  }

  def initialize(network)
    @network = network
    @map = network.map
    @direction = :north
    @game_stage = :early
    @counter = 0
    @moves = []
    @network.log(search_distance, :debug)
  end

  def rotate_direction
    @counter += 1
    @counter = 0 if @counter >= 4
    @direction = GameMap::CARDINALS[@counter]
  end

  def reset_turn
    @moves = []
    @game_stage = nil
  end

  def move(site)
    mover = PieceMover.new(site, map, @direction, search_distance)
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
