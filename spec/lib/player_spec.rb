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

  describe '#as_json' do
    context 'when player has rfid' do
      before { subject.stub name: nil }

      it 'picks the rfid' do
        subject.as_json.should == {rfid: '123456789012'}
      end
    end

    context 'when player has name' do
      before { subject.stub rfid: nil }

      it 'picks the name' do
        subject.as_json.should == {name: 'maradona'}
      end
    end
  end
end