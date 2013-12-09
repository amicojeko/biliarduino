require 'spec_helper'

describe Player do
  let(:opts) { {name: 'maradona', rfid: '123456789012'} }

  subject { Player.new(opts) }

  it { should be_a Player }

  [:rfid, :name].each do |accessor|
    it "should have '#{accessor}' reader" do
      should respond_to accessor
    end

    it "should have '#{accessor}= writer" do
      should respond_to "#{accessor}="
    end
  end

  it 'loads dummy names' do
    Player::NAMES.should be_an Array
  end

  it 'picks the dummy names' do
    Player.next_name.should == 'maradona'
    Player.next_name.should == 'falcao'
  end
end