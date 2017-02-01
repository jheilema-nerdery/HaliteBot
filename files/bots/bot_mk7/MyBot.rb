$:.unshift(File.dirname(__FILE__))
require 'networking'
require 'decisionmaker'

name = defined?(NAME) ? NAME : "RubyBotMk7"
network = Networking.new(name)
tag, map = network.configure
decisionmaker = Decisionmaker.new(network)
counter = 0

while true
  moves = []
  network.frame

  map.content.values.each do |site|
    if site.owner == tag
      decisionmaker.move(site)
    end
  end

  network.send_moves(decisionmaker.moves)
  counter += 1
  decisionmaker.reset_moves
  decisionmaker.rotate_direction if counter % 20 == 0
end

