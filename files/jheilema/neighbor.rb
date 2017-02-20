require 'forwardable'

class Neighbor
  extend Forwardable

  attr_accessor :direction, :distance

  def_delegators :@site, :owner, :strength, :production, :location,
                         :neighbors, :neighbor, :self_with_neighbors, :moves,
                         :neutral?, :enemy?, :friendly?, :victim?,
                         :strong_enemy?, :dangerous?, :blank_neutral?,
                         :planned_strength, :interesting, :being_a_wall?,
                         :at_max?, :proposed_strength_too_big?, :overflowing?,
                         :score, :score=, :initial_score,
                         :flow_direction, :flow_direction=,
                         :discounted_score, :discounted_score=,
                         :redlight!, :redlight,
                         :greenlight!, :greenlight,
                         :==, :eql?, :hash

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
    neighbors.any?(&:enemy?)
  end

  def to_s
    "Neighbor #{direction} #{@site}"
  end

end
