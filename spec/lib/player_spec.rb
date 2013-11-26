require 'spec_helper'

describe Player do
  let(:id)   { '33' }
  let(:role) { Player::ROLES.first }

  subject { Player.new(id, role) }

  it { should be_a Player }

  it 'raise an error when role is not valid' do
    expect do
      Player.new(id, :pivot)
    end.to raise_error
  end

  [:code, :role, :name].each do |accessor|
    it "should have '#{accessor}' reader" do
      should respond_to accessor
    end

    it "should have '#{accessor}= writer" do
      should respond_to "#{accessor}="
    end
  end

  it 'raise an error when role is not valid' do
    expect { Player.new(id, :pivot) }.to raise_error
  end

  it 'pads code with zeros' do
    player = Player.new('asd')
    player.code.should == '000000000asd'
  end
end