class Player
  ROLES = [:defense, :attack]

  attr_accessor :rfid, :role, :name


  def initialize(rfid, role=:defense)
    @rfid = rfid
    @role = role
    validate_role
  end

  private

  def validate_role
    raise "player role #{role} is invalid" unless ROLES.include? role
  end
end
