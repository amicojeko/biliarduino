require 'spec_helper'

describe RegisteredPlayer do
  let(:opts) { {rfid: '123456789012'} }

  subject { RegisteredPlayer.new(opts) }

  it { should be_a RegisteredPlayer }

  [:rfid].each do |accessor|
    it "should have '#{accessor}' reader" do
      should respond_to accessor
    end

    it "should have '#{accessor}= writer" do
      should respond_to "#{accessor}="
    end
  end

  it '#as_json picks the rfid' do
    subject.as_json.should == {rfid: '123456789012', type: 'RegisteredPlayer'}
  end
end