class Team
  attr_accessor :code, :players

  def initialize(code, opts={})
    @code    = code
    @players = opts.fetch(:players, [])
  end

  def add_player(player)
    self.players << player
  end

  def player_rfids
    players.map { |p| p.rfid }
  end
end
