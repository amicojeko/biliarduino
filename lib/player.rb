require 'yaml'

class Player
  NAMES = YAML.load_file(File.expand_path 'config/dummy_players.yml')

  attr_accessor :rfid, :name

  class << self
    attr_accessor :name_index

    def next_name
      NAMES[name_index].tap { self.name_index += 1 }
    end
  end

  self.name_index = 0


  def initialize(opts)
    @rfid = opts[:rfid]
    @name = opts[:name]
  end
end
