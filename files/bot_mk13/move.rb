class Move

  attr_reader :location, :direction, :site

  def initialize(location, direction, site)
    @location = location
    @direction = direction
    @site = site
  end

  def strength
    if direction == :still
      site.strength + site.production
    else
      site.strength
    end
  end

  def to_s
    [location.x, location.y, GameMap::DIRECTIONS.index(direction)].join(' ')
  end

end
