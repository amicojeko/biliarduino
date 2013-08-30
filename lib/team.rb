class Team
  attr_accessor :id, :score, :name

  #TODO: aggiungere l'attributo "name" al team

  def initialize(id)
    @id     = id
    @score  = 0
    @winner = false
    @name   = id.to_s.upcase
  end

  def set_winner
    @winner = true
  end

  def winner?
    @winner
  end
end
