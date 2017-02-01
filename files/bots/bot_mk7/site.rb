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

end
