class Player
  attr_accessor :rfid, :name

  def initialize(opts)
    @rfid = opts[:rfid]
    @name = opts[:name]
  end
end
