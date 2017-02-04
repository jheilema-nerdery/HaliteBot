require 'forwardable'

class Neighbor
  extend Forwardable

  attr_accessor :direction, :distance

  def_delegators :@site, :owner, :strength, :production, :location, :neighbors,
                         :neutral?, :enemy?, :friendly?, :victim?,
                         :moves, :planned_strength, :interesting,
                         :at_max?, :proposed_strength_too_big?

  def initialize(site, direction, distance = 1)
    @site = site
    @direction = direction
    @distance = distance
  end

  def interesting_per_distance
    score = @site.interesting
    score/distance
  end

  def near_an_enemy?
    neighbors.values.any?{|s| s.enemy? }
  end

  def being_a_wall?
    neutral? && strength > 0 && near_an_enemy?
  end

  def to_s
    "Neighbor #{direction} #{location.x} #{location.y}"
  end

end
