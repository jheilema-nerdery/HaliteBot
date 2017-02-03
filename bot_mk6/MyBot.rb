$:.unshift(File.dirname(__FILE__))
require 'networking'
require 'decisionmaker'

name = defined?(NAME) ? NAME : "RubyBotMk6"
network = Networking.new(name)
tag, map = network.configure
decisionmaker = Decisionmaker.new(network)
counter = 0

while true
  moves = []
  map = network.frame
  decisionmaker.map = map

  (0...map.height).each do |y|
    (0...map.width).each do |x|
      loc = Location.new(x, y)
      site = map.site(loc)

      if site.owner == tag
        moves << decisionmaker.move(site, loc)
      end
    end
  end

  network.send_moves(moves)
  counter += 1
  decisionmaker.rotate_direction if counter % 20 == 0
end

