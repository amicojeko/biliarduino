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

  # TODO this can be dried up... before that, check what sound constants are really used and delete the unnecessary ones
  # def play_once_idle_sound
  #   return if played_once[:idle_sound]
  #   played[:idle_sound] = true
  #   play_idle_sound
  # end

  # def reset_idle_sound
  #   played.delete :idle_sound
  # end

  # def play_skip_registration
  #   play_sound SKIP_REGISTRATION
  # end

  # def play_start_sound
  #   play_sound START_SOUND
  # end

  # def play_idle_sound
  #   play_sound IDLE_SOUND
  # end

  # def play_register_sound
  #   play_sound REGISTER_SOUND
  # end

  # def play_player_registered
  #   play_sound PLAYER_REGISTERED
  # end
  # def play_match_start
  #   play_sound MATCH_START
  # end

  # def play_match_end
  #   play_sound MATCH_END
  # end

  def play_random_goal
    play_sound goal.sample
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
