$:.unshift(File.dirname(__FILE__))
require 'networking'

network = Networking.new("RubyBotMk3")
tag, map = network.configure
MAX_STRENGTH = 255

def move(site, location, map, network)
  if site.strength < 5 || site.strength < 5 * site.production
    return Move.new(location, :still)
  end

  neighbors = map.neighbors(location)

  if neighbors.values.all?{|s| s.owner == site.owner }
    return Move.new(location, [:south, :west].shuffle.first)
  end

  largest = neighbors.select do |dir, s|
    s.owner == site.owner && s.strength > site.strength && ((s.strength + site.strength) < MAX_STRENGTH)
  end.keys.shuffle.first
  if largest
    return Move.new(location, largest)
  end

  target = neighbors.select do |dir, s|
    s.strength < site.strength && s.owner != site.owner
  end.to_a.sort{|a,b| a[1].strength <=> b[1].strength }.first
  network.log(target.to_s)

  if target
    return Move.new(location, target[0])
  end

  Move.new(location, :still)
end

while true
  moves = []
  map = network.frame

  (0...map.height).each do |y|
    (0...map.width).each do |x|
      loc = Location.new(x, y)
      site = map.site(loc)

      if site.owner == tag
        moves << move(site, loc, map, network)
      end
    end
  end

  network.send_moves(moves)
end

