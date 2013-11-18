require 'spec_helper'

describe Server do
  subject { Server }

  it { should respond_to :start_match }
  it { should respond_to :update_match }
  it { should respond_to :end_match }
end