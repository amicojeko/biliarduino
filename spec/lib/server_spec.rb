require 'spec_helper'

describe Server do
  def build_teams
    team_a = Team.new(:a, :players => [Player.new('1'), Player.new('2')])
    team_b = Team.new(:b, :players => [Player.new('3'), Player.new('4')])
    [team_a, team_b]
  end

  subject { Server }

  it { should respond_to :start_match }
  it { should respond_to :update_match }
  it { should respond_to :close_match }

  describe '#domain' do
    it 'returns expected string' do
      Server.domain.to_s.should == 'http://192.168.16.156:3000'
    end
  end

  describe '#get_player_params' do
    it 'builds an hash with expected keys' do
      hash = Server.get_player_params(build_teams)
      %w[player_1 player_2 player_3 player_4].each do |key|
        hash.keys.should include key
      end
    end
  end

  describe '#start_match' do
    it 'posts to the server url' do
      teams  = build_teams
      domain = Pathname.new('http://fakeserver.com')
      url    = "#{domain}/match"
      Server.stub(:domain => domain)
      FakeWeb.register_uri(:post, url, :body => '42', :status => ['200', 'OK']) # body is actually not used now
      Server.start_match(teams).body.should == '42'
    end
  end
end