class Team
  attr_accessor :code, :score, :name, :players

  def initialize(code, opts={})
    @score   = 0
    @code    = code
    @winner  = false
    @players = opts.fetch(:players, [])
    @name    = code.to_s.upcase # TODO once we have a table, let the users edit the name
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

  def player_codes
    players.map { |p| p.code }
  end
end
