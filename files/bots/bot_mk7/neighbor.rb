require 'forwardable'

class Neighbor
  extend Forwardable

  attr_accessor :direction

  def_delegators :@site, :owner, :strength, :production, :location

  def initialize(site, direction)
    @site = site
    @direction = direction
  end

end
