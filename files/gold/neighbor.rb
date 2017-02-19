require 'forwardable'

class Neighbor
  extend Forwardable

  attr_accessor :direction, :distance

  def_delegators :@site, :owner, :strength, :production, :location,
                         :neighbors, :moves,
                         :neutral?, :enemy?, :friendly?, :victim?,
                         :planned_strength, :interesting,
                         :at_max?, :proposed_strength_too_big?, :overflowing?,
                         :score, :score=, :flow_direction, :flow_direction=

  def initialize(site, direction, distance = 1)
    @site = site
    @direction = direction
    @distance = distance
  end

  def interesting_per_distance
    score = @site.interesting
    score/(distance*2 - 1)
  end

  def near_an_enemy?
    neighbors.values.any?{|s| s.enemy? }
  end

  def being_a_wall?
    neutral? && strength > 0 && near_an_enemy?
  end

  def battlefront?
    neutral? && strength == 0
  end

  def to_s
    "Neighbor #{direction} #{location.x} #{location.y}"
  end

end
