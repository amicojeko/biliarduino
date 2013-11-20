class Player
  ROLES = [:defense, :attack]

  attr_accessor :code, :role, :name


  def initialize(code, role=:defense)
    @code = code
    @role = role
    @name = code.to_s.upcase # TODO once we have a table, let the users edit the name
    validate_role
  end

  private

  def validate_role
    raise "player role #{role} is invalid" unless ROLES.include? role
  end
end
