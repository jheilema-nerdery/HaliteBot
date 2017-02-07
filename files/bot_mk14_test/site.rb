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
