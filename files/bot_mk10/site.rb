class Site
  attr_accessor :owner, :strength, :production, :location

  def initialize(args)
    @owner = args[:owner]
    @strength = args[:strength]
    @production = args[:production]
    @location = args[:location]
  end

  def is_weak?
    strength < 5 || (strength < 5*production)
  end

  def interesting
    if strength == 0
      return production*2
    end
    (production*2).to_f/strength
  end

  def neutral?
    owner == 0
  end

  def enemy?(me)
    owner != me && owner != 0
  end

  def mine?(me)
    owner == me
  end

  def victim?(me)
    owner != me
  end

end
