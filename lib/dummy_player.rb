require 'yaml'
require_relative 'player'

class DummyPlayer < Player
  NAMES = YAML.load_file(File.expand_path 'config/dummy_players.yml')

  attr_accessor :name

  class << self
    attr_accessor :name_index

    def next_name
      NAMES[name_index].tap do
        self.name_index = (name_index + 1) % NAMES.size
      end
    end
  end

  self.name_index = 0


  def initialize
    @name = self.class.next_name
  end

  def as_json(opts={})
    {name: name}
  end
end
