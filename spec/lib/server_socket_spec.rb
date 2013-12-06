require 'spec_helper'

describe ServerSocket do
  def build_teams
    team_a = Team.new(:a, :players => [Player.new('1'), Player.new('2')])
    team_b = Team.new(:b, :players => [Player.new('3'), Player.new('4')])
    [team_a, team_b]
  end

  let(:table) { double.as_null_object }

  before { ServerSocket.any_instance.stub build_socket: double.as_null_object }

  subject { ServerSocket.new(table) }

  it { should respond_to :start_match }
  it { should respond_to :update_match }
  it { should respond_to :close_match }

  describe '#start_match_json' do
    it 'builds an hash with expected keys' do
      json = subject.start_match_json(build_teams)
      %w["player_1": "player_2": "player_3": "player_4":].each do |key|
        json.should include key
      end
    end
  end

  describe ServerSocket::Message do
    let(:msg) { "[[\"websocket_rails.ping\",{\"id\":null,\"channel\":null,\"user_id\":null,\"data\":{\"id\": \"42\"},\"success\":null,\"result\":null,\"server_token\":null}]]" }
    let(:type) { :text }

    subject { ServerSocket::Message.new msg, type }
    %w[json data event type].each do |method|
      it { should respond_to method }
    end

    it 'has expected event' do
      subject.event.should == 'websocket_rails.ping'
    end

    it 'has expected data' do
      subject.data.should == {'id' => '42'}
    end

    it 'is ping event' do
      subject.should be_ping
    end
  end
end