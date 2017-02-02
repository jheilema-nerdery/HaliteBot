$:.unshift(File.dirname(__FILE__))
require 'networking'
require 'decisionmaker'

name = defined?(NAME) ? NAME : "RubyBotMk11"

network = Networking.new(name)
player, map = network.configure
decisionmaker = Decisionmaker.new(network, player, map)

while true
  network.frame

  decisionmaker.reset_turn
  decisionmaker.make_decisions

  network.send_moves(decisionmaker.moves)
end

