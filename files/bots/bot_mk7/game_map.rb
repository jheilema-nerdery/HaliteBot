class GameMap

  CARDINALS = [:north, :east, :south, :west]
  DIRECTIONS = [:still] + CARDINALS

  attr_reader :width, :height
  attr_reader :content

  def initialize(options = {})
    @width = options[:width]
    @height = options[:height]
    @content = {}

    options[:owners].each_with_index do |owner, index|
      y, x = index.divmod(@width)

      site = Site.new({
        owner: owner,
        strength: options[:strengths][index],
        production: options[:production][index],
        location: Location.new(x, y)
      })

      @content["#{y}_#{x}"] = site
    end
  end

  def update(owner_data, strength_data)
    owner_data.each_with_index do |owner, index|
      y, x = index.divmod(@width)
      @content["#{y}_#{x}"].owner = owner
      @content["#{y}_#{x}"].strength = strength_data[index]
    end
  end

  def site(location, direction = :still)
    new_loc = find_location(location, direction)
    content["#{new_loc.y}_#{new_loc.x}"]
  end

  def neighbors(location)
    CARDINALS.map do |direction|
      Neighbor.new(site(location, direction), direction)
    end
  end

  def find_location(location, direction)
    x, y = location.x, location.y

    case direction
    when :north
      y = y == 0 ? height - 1 : y - 1
    when :east
      x = x == width - 1 ? 0 : x + 1
    when :south
      y = y == height - 1 ? 0 : y + 1
    when :west
      x = x == 0 ? width - 1 : x - 1
    end

    Location.new(x, y)
  end

  def distance_between(from, to)
    dx = (from.x - to.x).abs
    dy = (from.y - to.y).abs

    dx = width - dx if dx > width / 2
    dy = height - dy if dy > height / 2

    dx + dy
  end

  def angle_between(from, to)
    dx = to.x - from.x
    dy = to.y - from.y

    if dx > width - dx
      dx -= width
    elsif -dx > width + dx
      dx += width
    end

    if dy > height - dy
      dy -= height
    elsif -dy > height + dy
      dy += height
    end

    Math.atan2(dy, dx)
  end

  def in_bounds(loc)
    loc.x.between?(0, width - 1) && loc.y.between?(0, height - 1)
  end

end
