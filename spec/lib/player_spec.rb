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
end