require 'securerandom'

class Player
  ROLES = [:defense, :attack]

  attr_accessor :code, :role, :name


  def self.random_rfid
    SecureRandom.base64(8)
  end


  def initialize(code, role=:defense)
    @code = build_code(code)
    @role = role
    @name = code.to_s.upcase # TODO once we have a table, let the users edit the name
    validate_role
  end

  def build_code(code)
     code.size == 12 ? code : self.class.random_rfid
  end

  private

  def validate_role
    raise "player role #{role} is invalid" unless ROLES.include? role
  end
end
