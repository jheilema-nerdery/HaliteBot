require_relative '../site'
require_relative '../neighbor'
require_relative '../location'

describe Site do
  it 'can be initialized' do
    site = Site.new({
        owner: 0,
        player: 1,
        strength: 50,
        production: 5,
        location: Location.new(1, 2)
      })
  end

  describe 'comparing one site to another' do
    it 'is the same if the location is the same' do
      site1 = Site.new({ location: Location.new(1, 2) })
      site2 = Site.new({ location: Location.new(1, 2) })
      expect(site1).to eq site2
    end
    it 'is not the same if the location is different' do
      site1 = Site.new({ location: Location.new(2, 3) })
      site2 = Site.new({ location: Location.new(1, 2) })
      expect(site1).to_not eq site2
    end
    it 'can be compared to a neighbor object' do
      site1 = Site.new({ location: Location.new(1, 2) })
      site2 = Site.new({ location: Location.new(1, 2) })
      neighbor = Neighbor.new(site2, :still, 0)
      expect(site1).to eq neighbor
      expect(site2).to eq neighbor
      expect(neighbor).to eq site1
      expect(neighbor).to eq site2
    end
    it 'can be identified from an array' do
      site1 = Site.new({ location: Location.new(1, 2) })
      site2 = Site.new({ location: Location.new(1, 2) })
      site3 = Site.new({ location: Location.new(2, 3) })
      site4 = Site.new({ location: Location.new(5, 3) })
      neighbor = Neighbor.new(site3, :still, 0)
      array = [site1, site3]
      expect(array).to include site1
      expect(array).to include site2
      expect(array).to include site3
      expect(array).to include neighbor
      expect(array).to_not include site4
    end
  end

end
