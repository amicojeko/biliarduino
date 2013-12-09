require 'spec_helper'

describe Sound do
  before { Sound.any_instance.stub play_sound: true }

  it { should respond_to :play_idle_sound }
  it { should respond_to :reset_idle_sound }
  it { should respond_to :play_once_idle_sound }
  it { should respond_to :play_start_sound }
  it { should respond_to :reset_start_sound }
  it { should respond_to :play_once_start_sound }

  describe '#play_once_start_sound' do
    it 'sets the sound as played' do
      subject.play_once_start_sound
      subject.played['start_sound'].should be_true
    end
  end

  describe '#reset_start_sound' do
    before { subject.play_once_start_sound }

    it 'unsets the sound as played' do
      subject.reset_start_sound
      subject.played['start_sound'].should be_nil
    end
  end

  describe '#play_match_end' do
    it 'plays the expected sound' do
      subject.should_receive(:play_sound).with(Sound::MATCH_END)
      subject.play_match_end
    end
  end
end