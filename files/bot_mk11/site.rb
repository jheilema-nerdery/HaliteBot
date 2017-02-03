class Site
  attr_accessor :owner, :strength, :production, :location, :neighbors

  def initialize(args)
    @owner = args[:owner]
    @strength = args[:strength]
    @production = args[:production]
    @location = args[:location]
    @player = args[:player]
    @neighbors = {}
  end

  def is_weak?
    strength < 10 || (strength < 5*production)
  end

  def interesting
    if strength == 0
      return production**1.7
    end
    (production**1.7).to_f/strength
  end

  def neutral?
    owner == 0
  end

  def enemy?
    owner != @player && owner != 0
  end

  def mine?
    owner == @player
  end

  def victim?
    owner != @player
  end

end
