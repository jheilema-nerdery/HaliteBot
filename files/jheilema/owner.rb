class Owner
  attr_accessor :tag

  def initialize(tag, sites)
    @tag = tag
    @sites = sites
  end

  def strength
    @sites.map(&:strength).reduce(:+)
  end

  def production
    @sites.map(&:production).reduce(:+)
  end

end
