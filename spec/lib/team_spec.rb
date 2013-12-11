require 'spec_helper'

describe Team do
  let(:code) { :asdasd }
  let(:team) { Team.new(code) }

  [:code, :players].each do |accessor|
    it "has '#{accessor}' reader" do
      team.should respond_to accessor
    end

    it "has '#{accessor}=' writer" do
      team.should respond_to "#{accessor}="
    end
  end

  it 'requires a code' do
    expect { Team.new }.to raise_error
  end

  it 'has no players' do
    team.players.should be_empty
  end

  describe '#add_player' do
    it 'adds the player' do
      player = double
      team.add_player player
      team.players.should include player
    end
  end

  describe '#players_as_json' do
    context 'when players are real players' do
      it 'has expected values' do
        team.add_player RegisteredPlayer.new(rfid: code)
        team.players_as_json.map {|arr| arr.values.should =~ ['RegisteredPlayer', code]}
      end
    end
    context 'when players are dummy players' do
      it 'has expected values' do
        team.add_player DummyPlayer.new
        team.players_as_json.map {|arr| arr.values.should include 'DummyPlayer'}
      end
    end
  end
end