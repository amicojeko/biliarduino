require 'spec_helper'

describe Server do
  subject { Server }

  it { should respond_to :start_match }
  it { should respond_to :update_match }
  it { should respond_to :close_match }

  describe '#domain' do
    it 'returns expected string' do
      Server.domain.should == 'http://192.168.0.1:3000'
    end
  end
end