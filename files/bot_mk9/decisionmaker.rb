require 'piece_mover'

class Decisionmaker
  attr_accessor :map, :moves, :network

  def initialize(network)
    @network = network
    @map = network.map
    @direction = :north
    @counter = 0
    @moves = []
  end

  def rotate_direction
    @counter += 1
    @counter = 0 if @counter >= 4
    @direction = GameMap::CARDINALS[@counter]
  end

  def reset_turn
    @moves = []
  end

  def move(site)
    mover = PieceMover.new(site, map, @direction)
    @moves << mover.calculate_move
  end

end
