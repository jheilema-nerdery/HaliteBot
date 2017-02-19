class Site
  MAX_STRENGTH = 255

  attr_accessor :owner, :strength, :production, :location, :neighbors, :moves

  def initialize(args)
    @owner = args[:owner]
    @strength = args[:strength]
    @production = args[:production]
    @location = args[:location]
    @player = args[:player]
    @neighbors = {}
    @moves = []
  end

  def to_s
    "Site #{location} str#{strength} prod#{production} owner#{owner}"
  end

  def add_move(direction)
    if direction == :still
      @moves << Move.new(location, :still, self)
    else
      Networking.log("Moving! #{location} #{direction}")
      neighbors[direction].moves << Move.new(location, direction, self)
    end
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

  def is_weak?
    strength < 5 || (strength < 5*production)
  end

  def is_strong?
    !is_weak?
  end

  def at_max?
    strength == MAX_STRENGTH
  end

  def bordering_me?
    neighbors.values.any?{|n|
      n.battlefront? && (n.neighbors.values.any?(&:friendly?) || (n.neighbors.values.any?{|nn| nn.battlefront? && nn.neighbors.values.any?(&:friendly?) }))
    }
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

  def surrounding_sites
    dirs = GameMap::CARDINALS
    dirs.each_with_index.map{|dir, idx| [neighbors[dir], neighbors[dir].neighbors[dirs[idx-3]]] }.flatten
  end

  def walls
    @neighbors.values.select(&:being_a_wall?)
  end

  def in_a_warzone?
    @neighbors.values.any?{|s| s.strength == 0 && s.neutral? }
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
