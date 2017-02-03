$:.unshift(File.dirname(__FILE__))
require 'networking'
require 'decisionmaker'

NAME = "RubyBotMk11"

network = Networking.new
player, map = network.configure
decisionmaker = Decisionmaker.new(network, player, map)

while true
  network.frame

  decisionmaker.reset_turn
  decisionmaker.make_decisions

  network.send_moves(decisionmaker.moves)
end

