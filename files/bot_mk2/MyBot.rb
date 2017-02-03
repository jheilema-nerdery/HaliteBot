$:.unshift(File.dirname(__FILE__))
require 'networking'

name = defined?(NAME) ? NAME : "RubyBotMk2"
network = Networking.new(name)
tag, map = network.configure

def move(site, location, map)
  if site.strength < 5 * site.production
    return Move.new(location, :still)
  end

  neighbors = map.neighbors(location)

  if neighbors.values.all?{|s| s.owner == site.owner }
    return Move.new(location, [:north, :west].shuffle.first)
  end

  target = neighbors.select{|dir, s| s.strength < site.strength && s.owner != site.owner }.keys.shuffle.first
  if target
    return Move.new(location, target)
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
        moves << move(site, loc, map)
      end
    end
  end

  network.send_moves(moves)
end

