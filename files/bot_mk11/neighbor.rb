require 'forwardable'

class Neighbor
  extend Forwardable

  attr_accessor :direction, :distance

  def_delegators :@site, :owner, :strength, :production, :location, :neighbors,
                         :neutral?, :enemy?, :mine?, :victim?,
                         :moves

  def initialize(site, direction, distance = 1)
    @site = site
    @direction = direction
    @distance = distance
  end

  def interesting
    score = @site.interesting
    score/distance
  end

  def near_an_enemy?
    @neighbors.values.any?{|s| s.enemy? }
  end

  def to_s
    "Neighbor #{direction} #{location.x} #{location.y}"
  end

end
