class Player
  ROLES = [:goalkeeper, :striker]
  attr_accessor :id, :role

  def initialize(id, role)
    @id   = id
    @role = role
    validate_role
  end

  private

  def validate_role
    raise "player role #{role} is invalid" unless ROLES.include? role
  end
end
