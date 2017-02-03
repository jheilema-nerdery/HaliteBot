class Move

  attr_reader :location, :direction

  def initialize(location, direction, site)
    @location = location
    @direction = GameMap::DIRECTIONS.index(direction)
    @site = site
  end

  def to_s
    [location.x, location.y, direction].join(' ')
  end

end
