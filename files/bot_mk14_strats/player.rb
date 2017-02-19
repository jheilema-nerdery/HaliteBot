class Player
  attr_accessor :token

  def initialize(token, starting, distance_to)
    @token = token
    @starting = starting
    @distance_to = distance_to
  end

  def to_s
    "Token: #{token} starting #{@starting.location} distance_to: #{@distance_to}"
  end
end
