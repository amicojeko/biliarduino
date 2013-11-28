require 'spec_helper'

describe Server do
  def build_teams
    team_a = Team.new(:a, :players => [Player.new('1'), Player.new('2')])
    team_b = Team.new(:b, :players => [Player.new('3'), Player.new('4')])
    [team_a, team_b]
  end

  before { Server.any_instance.stub :build_connection => double.as_null_object }

  subject { Server.new }

  it { should respond_to :start_match }
  it { should respond_to :update_match }
  it { should respond_to :close_match }

  describe '#domain' do
    it 'returns expected string' do
      subject.domain.to_s.should == 'ws://localhost:3000'
    end
  end

  describe '#get_player_params' do
    it 'builds an hash with expected keys' do
      hash = subject.get_player_params(build_teams)
      %w[player_1 player_2 player_3 player_4].each do |key|
        hash.keys.should include key
      end
    end
  end

  describe '#start_match' do
    it 'it uses websockets' do
      pending
      subject.start_match(build_teams).should be_a(TCPSocket)
    end
  end
end