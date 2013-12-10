require 'spec_helper'

describe DummyPlayer do
  it 'loads dummy names' do
    DummyPlayer::NAMES.should be_an Array
  end

  describe '::next_name' do
    it 'picks the dummy names' do
      DummyPlayer.name_index = 0
      DummyPlayer.next_name.should == 'maradona'
      DummyPlayer.next_name.should == 'falcao'
    end
  end

  describe '#as_json' do
    it 'picks the name' do
      subject.stub name: 'maradona'
      subject.as_json.should == {name: 'maradona'}
    end
  end
end