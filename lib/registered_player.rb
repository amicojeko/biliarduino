class Player
  attr_accessor :rfid

  def initialize(opts)
    @rfid = opts[:rfid]
  end

  def as_json(opts={})
    {rfid: rfid, type: self.class.name }
  end
end
