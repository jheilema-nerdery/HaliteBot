class Location

  attr_reader :x, :y

  def initialize(x, y)
    @x, @y = x, y
  end

  def to_s
    [x, y].join(' ')
  end

  def ==(other_location)
    other_location.x == x && other_location.y == y
  end

end
