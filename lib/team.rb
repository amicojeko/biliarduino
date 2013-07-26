class Team
  attr_accessor :id, :score

  #TODO: aggiungere l'attributo "name" al team

  def initialize(id)
    @id     = id
    @score  = 0
    @winner = false
  end

  def make_winner
    @winner = true
  end

  def winner?
    @winner
  end
end
