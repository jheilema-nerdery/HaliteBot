class GameMap

  CARDINALS = [:north, :east, :south, :west]
  DIRECTIONS = [:still] + CARDINALS

  attr_reader :width, :height, :owners
  attr_reader :content

  def initialize(options = {})
    @width = options[:width]
    @height = options[:height]
    @owners = options[:owners].uniq.length - 1
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

  def fetch_nearby(location, distance)
    (1...distance).map do |dist|
      CARDINALS.map do |cardinal|
        (0..(dist*2-1)).map do |count|
          case cardinal
          when :north
            x = location.x + count - dist
            y = location.y - dist
          when :south
            x = location.x - count + dist
            y = location.y + dist
          when :east
            x = location.x + dist
            y = location.y - count + dist
          when :west
            x = location.x - dist
            y = location.y + count - dist
          end
          Neighbor.new(site(fetch_in_bounds(x, y)), cardinal)
        end
      end
    end.flatten
  end

  def fetch_in_bounds(x, y)
    if x >= width - 1
      x = x - width
    end
    if x < 0
      x = x + width
    end

    if y >= height - 1
      y = y - height
    end
    if y < 0
      y = y + height
    end
    Location.new(x, y)
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
    dx, dy = deltas(from, to)
    Math.atan2(dy, dx)
  end

  def direction(from, to)
    dx, dy = deltas(from, to)

    if dx >= dy
      if dx < 0
        return :east
      end
      return :west
    end

    if dy < 0
      return :south
    end
    return :north
  end

  def in_bounds(loc)
    loc.x.between?(0, width - 1) && loc.y.between?(0, height - 1)
  end

  def deltas(from, to)
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
    [dx, dy]
  end

end
