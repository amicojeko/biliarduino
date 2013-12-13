require 'omxplayer'

class Sound
  IDLE_SOUND        = {name: 'media/idle.wav'         , duration: 2}
  START_SOUND       = {name: 'media/fischio2.wav'     , duration: 1}
  REGISTER_SOUND    = {name: 'media/register.wav'     , duration: 2}
  MATCH_START       = {name: 'media/match_start.wav'  , duration: 1}
  MATCH_END         = {name: 'media/fischiofine.wav'  , duration: 3}
  PLAYER_REGISTERED = {name: 'media/beep-7.wav',        duration: 1}
  SKIP_REGISTRATION = {name: 'media/fischio2.wav',      duration: 1}


  attr_reader :omx, :goal, :supporters, :music, :played


  def initialize
    @omx        = Omxplayer.instance
    @played     = {}
    @goal       = Dir.glob('./media/goal*.wav')
    @music      = Dir.glob('./media/music*.mp3')
    @supporters = Dir.glob('./media/tifo*.wav')
  end

  def reset_sounds
    played.clear
  end

  constants.each do |constant|
    const = const_get(constant)
    sound = constant.to_s.downcase
    define_method "play_#{sound}" do
      play_sound const
    end

    define_method "reset_#{sound}" do
      played.delete sound
    end

    define_method "play_once_#{sound}" do
      return if played[sound]
      played[sound] = true
      send "play_#{sound}"
    end
  end

  def play_random_goal
    play_sound name: goal.sample, duration: 5
    play_background_supporters
  end

  def play_background_supporters
    omx.open supporters.sample
  end

  def play_background_music
   omx.open music.sample
  end

  def play_register_player_sound(n)
    play_sound "./media/player_#{n}.wav"
  end

  def play(tune)
    play_sound tune
  end

  private

  def play_sound(sound)
    stop_sound
    sound = {name: sound, duration: 2} if sound.is_a?(String)
    omx.open sound[:name]
    sleep sound[:duration]
  end

  def stop_sound
    system 'killall -9 omxplayer.bin'
  end
end
