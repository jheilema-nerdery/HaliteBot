require 'forwardable'

class Neighbor
  extend Forwardable

  attr_accessor :direction, :distance

  def_delegators :@site, :owner, :strength, :production, :location,
                         :neutral?, :enemy?, :mine?, :victim?

  def initialize(site, direction, distance = 1)
    @site = site
    @direction = direction
    @distance = distance
  end

  def interesting
    score = @site.interesting
    score/distance
  end

end
