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

  describe '#player_rfids' do
    it 'returns player rfids' do
      %w[123 456].each do |rfid|
        team.add_player Player.new(rfid)
      end
      team.player_rfids.should be_all { |id| %w[123 456].include? id }
    end
  end
end