class Site
  MAX_STRENGTH = 255

  attr_accessor :owner, :strength, :production, :location, :moves,
                :score, :flow_direction, :discounted_score,
                :redlight, :greenlight
  attr_writer :neighbors

  def initialize(args)
    @owner = args[:owner]
    @strength = args[:strength]
    @production = args[:production]
    @location = args[:location]
    @player = args[:player]
    @neighbors = {}
    @moves = []
    @score = nil
    @flow_direction = nil
    @discounted_score = nil
    @redlight = nil
    @greenlight = nil
  end

  def to_s
    "Site #{location} str#{strength} prod#{production} owner#{owner}"
  end

  def hash
    location.hash
  end
  def ==(other_site)
    location == other_site.location
  end
  alias eql? ==

  def redlight!
    @greenlight = false
    @redlight = true
  end

  def greenlight!
    @redlight = false
    @greenlight = true
  end

  def add_move(direction)
    if direction == :still
      @moves << Move.new(location, :still, self)
    else
      Networking.log("Moving! #{location} #{direction}")
      neighbor(direction).moves << Move.new(location, direction, self)
    end
  end

  def initial_score
    # 0 production sites are useless. don't capture them.
    # initial values for enemy sites are also useless.
    if production == 0 || enemy?
      return Float::INFINITY
    end

    # assume the site is on a battlefront, maybe not ours.
    # it's pretty valuable. there's overkill to be had around here,
    # more for each enemy.
    if blank_neutral?
      return neighbors.select(&:enemy?).length * Decisionmaker::ENEMY_ROI
    end

    # turns to recover!
    return strength.to_f/production
  end

  def neighbors
    @neighbors.values
  end

  def self_with_neighbors
    @self_with_neighbors ||= neighbors + [Neighbor.new(self, :still, 0)]
  end

  def neighbor(direction)
    @neighbors[direction]
  end

  def proposed_strength_too_big?(str)
    planned_strength + str > MAX_STRENGTH
  end

  def planned_strength
    moves.map(&:strength).inject(&:+) || 0
  end

  def overflowing?
    proposed_strength_too_big?(strength + production)
  end

  def dangerous?
    enemy? || blank_neutral? && self_with_neighbors.any?(&:strong_enemy?) && self_with_neighbors.any?{|n2| n2.moves.length > 0 }
  end

  def strong_enemy?
    enemy? && strength > 0
  end

  def blank_neutral?
    neutral? && strength == 0
  end

  def is_weak?(multiplier = 5)
    strength < multiplier || (strength < multiplier*production)
  end

  def at_max?
    strength == MAX_STRENGTH
  end

  def interesting
    if friendly?
      return 0
    end
    if strength == 0
      return production**2
    end
    (production**2).to_f/strength
  end

  def being_a_wall?(seen_enemies = [0, @player])
    neutral? && strength > 0 && neighbors.any?(&:friendly?) && neighbors.any?{|n| !seen_enemies.include?(n.owner) || n.blank_neutral? }
  end

  def in_a_warzone?
    neighbors.any?(&:blank_neutral?)
  end

  def battlefront?
    blank_neutral? && neighbors.any?(&:friendly?)
  end

  def neutral?
    owner == 0
  end

  def enemy?
    !friendly? && !neutral?
  end

  def friendly?
    owner == @player
  end

  def victim?
    neutral? || enemy?
  end

end
