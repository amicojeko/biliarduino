require 'rspec'
require 'fakeweb'

parent = File.expand_path('../..', __FILE__)
Dir["#{parent}/lib/*.rb"].each {|file| require file }
