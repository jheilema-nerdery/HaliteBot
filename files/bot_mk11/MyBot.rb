$:.unshift(File.dirname(__FILE__))
require 'networking'
require 'decisionmaker'

name = defined?(NAME) ? NAME : "RubyBotMk11"
network = Networking.new(name)
tag, map = network.configure
decisionmaker = Decisionmaker.new(network)
counter = 0

while true
  network.frame

  counter += 1
  decisionmaker.reset_turn
  decisionmaker.rotate_direction if counter % 20 == 0

  map.content.values.each do |site|
    if site.owner == tag
      decisionmaker.move(site)
    end
  end

  network.send_moves(decisionmaker.moves)
end

