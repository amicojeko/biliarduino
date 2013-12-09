class Team
  attr_accessor :code, :score, :players

  def initialize(code, opts={})
    @score   = 0
    @code    = code
    @winner  = false
    @players = opts.fetch(:players, [])
  end

  def set_winner
    @winner = true
  end

  def add_player(player)
    self.players << player
  end

  def winner?
    @winner
  end

  def player_rfids
    players.map { |p| p.rfid }
  end
end
