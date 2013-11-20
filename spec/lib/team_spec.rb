require 'spec_helper'

describe Team do
  let(:code) { :asdasd }
  let(:team) { Team.new(code) }

  [:code, :score, :name, :players].each do |accessor|
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

  it 'is not winner' do
    team.should_not be_winner
  end

  it 'has zero score' do
    team.score.should be_zero
  end

  describe '#set_winner' do
    it 'makes the team winner' do
      team = Team.new(:asd)
      expect { team.set_winner }.to change(team, :winner?).to true
    end
  end
end