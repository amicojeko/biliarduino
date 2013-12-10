class Team
  attr_accessor :code, :players

  def initialize(code, opts={})
    @code    = code
    @players = opts.fetch(:players, [])
  end

  def add_player(player)
    self.players << player
  end

  def players_as_json
    players.map { |p| p.as_json }
  end
end
