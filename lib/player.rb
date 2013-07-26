class Player
  ROLES = [:defense, :attack]
  attr_accessor :id, :role

  def initialize(id, role=:defense)
    @id   = id
    @role = role
    validate_role
  end

  private

  def validate_role
    raise "player role #{role} is invalid" unless ROLES.include? role
  end
end
