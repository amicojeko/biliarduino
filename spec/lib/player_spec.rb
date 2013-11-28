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

  context 'when rfid length is not 12' do
    # this was the old way...
    # now we want that matches started without rfid cards
    # get random players each time, so we build a random
    # rfid for this scenario
    # it 'pads code with zeros' do
    #   player = Player.new('asd')
    #   player.code.should == '000000000asd'
    # end
    it 'builds a random 12 sequence chars code' do
      Player.new('asd').code.size.should == 12
    end

    describe '#build_code' do
      context 'when code is 12 chars size' do
        it 'returns the original code' do
          code = '1'*12
          subject.build_code(code).should == code
        end
      end

      context 'when code is not 12 chars size' do
        it 'builds a 12 chars code' do
          code = 'asd'
          subject.build_code(code).size.should == 12
          subject.build_code(code).should_not == code
        end
      end
    end
  end
end