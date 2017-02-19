require 'player'

class Strategizer
  attr_accessor :map, :players, :me

  def initialize(map, me)
    @map = map
    @players = []
    @starting_position = @map.sites.find{|s| s.friendly? }
    @me = Player.new(me, @starting_position, 0)

    Networking.log("map owners: #{@map.owners}", :debug)
    (1..@map.owners).select{|o| o != @me.token }.each do |owner|
      starting = @map.sites.find{|s| s.owner == owner }
      distance_to = @map.distance_between(@starting_position.location, starting.location)
      @players << Player.new(owner, starting, distance_to)
    end
    Networking.log("players: #{@players.join("\n")}", :debug)

    @interesting = map.sites.select(&:neutral?).sort_by!{|n| -n.interesting - n.surrounding_sites.map(&:interesting).reduce(:+) }[0..5]
    Networking.log("interesting: #{@interesting.join("\n")}", :debug)
  end

  def make_decisions
    sorted = my_pieces.select(&:is_strong?).sort_by{|s| -s.strength }
    to_move = sorted[0..(sorted.length*0.7).floor]
    Networking.log("to_move: " + to_move.join("\n"), :debug)

    # Attack enemies
    enemy_territory = @players.map do |p|
      map.sites.select{|s| s.owner == p.token }
    end
    warzones = enemy_territory.select{|terr| terr.any?{|s| s.bordering_me? } }

    Networking.log("Warzones: #{warzones.length}", :debug)

    attempted = []
    warzones.each do |warzone|
      enemy_targets = warzone.select(&:bordering_me?).sort_by{|t| t.strength }
      enemy_targets.each do |target|
        to_move = to_move + attempted
        to_move.sort_by!{|p| map.distance_between(p.location, target.location) }
        total = 0
        attempted = []
        until total > (target.strength + target.production) || to_move.empty?
          peice = to_move.shift
          mover = PieceMover.new(peice, map, :early, 5)
          strength_committed = mover.move_towards(target.location)
          total += strength_committed
          attempted << peice if strength_committed == 0
        end
      end
    end
    to_move = to_move + attempted

    # Tunnel to best place
    if warzones.length == 0 && interesting.length > 0
      target = interesting.sort_by{|s| my_pieces.map{|p| @map.distance_between(s.location, p.location) }.min }.first
      Networking.log("Most interesting Target: #{target}", :debug)

      count = 0
      strong = to_move.select(&:is_strong?)
      until strong.empty?
        count += 1
        mover = PieceMover.new(strong.shift, map, :early, 5)
        mover.move_towards(target.location, expanding = true)
      end
    end

    to_move.select(&:is_strong?).sort_by{|s| -s.strength }.each do |site|
      Networking.log("moving #{site}", :debug)
      mover = PieceMover.new(site, map, :early, 6)
      mover.expand
    end
  end

  def my_pieces
    map.sites.select{|s| s.friendly? && s.strength > 0 }
  end

  def interesting
    @interesting.select(&:victim?)
  end
end
