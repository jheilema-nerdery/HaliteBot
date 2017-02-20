require 'piece_mover'
require 'priority_queue'
require 'set'
require 'owner'

class Frame
  attr_reader :map, :player, :interacted_enemies,
              :battlefronts, :walls, :borders, :strength_hurdle

  def initialize(player, map, interacted_enemies)
    @player, @map = player, map

    owners = map.sites.group_by(&:owner).map{|player_tag, sites| Owner.new(player_tag, sites) }.select{|o| o.tag != 0 }
    @me = owners.find{|o| o.tag == @player }
    @owners = owners - [@me]

    @battlefronts = Set.new(map.sites.select(&:battlefront?))
    @known_enemies = interacted_enemies.merge(battlefronts.map{|s| s.neighbors.map(&:owner) }.flatten)

    @walls = Set.new(map.sites.select{|s| s.being_a_wall?(@known_enemies) })
    @borders = map.sites.select{|s| s.neutral? && s.production > 0 && !@walls.include?(s) && s.neighbors.any?(&:friendly?) }
  end

  def stalemate?
    # still somewhere to expand
    if @borders.length > 0
      return false
    end

    if @owners.length > 1
      return false
    end

    last_enemy = @owners.first
    Networking.log("last enemy: #{last_enemy.tag} #{last_enemy.strength} #{last_enemy.production}", :debug)
    Networking.log("me: #{@me.strength*0.95} #{@me.production*0.95}", :debug)
    # take a moment to build up strength
    if @me.strength*0.95 < last_enemy.strength && @me.production*0.95 > last_enemy.production
      return true
    end

    return false
  end

  def interactable_enemies
    @known_enemies
  end

  def multiplier
    @multiplier ||= battlefronts.length > 0 ? Decisionmaker::COMBAT_MULTIPLIER : Decisionmaker::BASE_MULTIPLIER
  end

  def my_pieces
    map.sites.select{|s| s.friendly? }
  end

  def strength_hurdle
    @strength_hurdle ||= begin
      my_pieces.each do |s|
        Networking.log("  -----  : #{s.discounted_score} - #{s} :: #{s.neighbors.min_by(&:discounted_score).discounted_score} - #{s.neighbors.min_by(&:discounted_score)}", :debug)
      end
      strengths = my_pieces.select{|s| s.neighbors.min_by(&:discounted_score).friendly? }.map(&:strength).sort.reverse
      Networking.log(" --- : Strengths: #{strengths}", :debug)
      return 0 if strengths.empty?
      # percent = (1 - strengths.length.to_f/map*height*map.width) * (Decisionmaker::INT_MAX - Decisionmaker::INT_MIN) + Decisionmaker::INT_MIN
      percent = (1 - strengths.length.to_f/(50*50)) * (Decisionmaker::INT_MAX - Decisionmaker::INT_MIN) + Decisionmaker::INT_MIN
      Networking.log(" --- : Percent: #{percent}", :debug)
      Networking.log(" --- : index: #{(strengths.length*percent).to_i}", :debug)
      strengths[(strengths.length*percent).to_i]
    end
  end

end
