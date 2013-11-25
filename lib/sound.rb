require 'omxplayer'

class Sound

  IDLE_SOUND        = {:name => 'media/idle.wav'         , :duration => 2}
  START_SOUND       = {:name => 'media/horn.mp3'         , :duration => 1}
  # GOAL_SOUND_A      = {:name => 'media/goal_team_a.wav'  , :duration => 1} # custom team
  # GOAL_SOUND_B      = {:name => 'media/goal_team_b.wav'  , :duration => 1} # custom team
  REGISTER_SOUND    = {:name => 'media/register.wav'     , :duration => 2}
  MATCH_START_SOUND = {:name => 'media/match_start.wav'  , :duration => 1}
  MATCH_END_SOUND   = {:name => 'media/match_end.wav'    , :duration => 1}
  WINNER_TEAM_A     = {:name => "media/winner_team_a.wav", :duration => 1} # custom team
  WINNER_TEAM_B     = {:name => "media/winner_team_b.wav", :duration => 1} # custom team
  PLAYER_REGISTERED = {:name => 'media/beep-7.wav',        :duration => 1}
  SKIP_REGISTRATION = {:name => 'media/beep-7.wav',        :duration => 1}

  attr_reader :omx, :goal, :supporters

	def initialize
		@omx  = Omxplayer.instance
		@goal = Dir.glob("./media/goal*.wav")
		@supporters = Dir.glob("./media/goal*.wav")
	end

	def play_idle_sound
		play_sound IDLE_SOUND
	end

	def play_register_sound
		play_sound REGISTER_SOUND
	end

	def play_random_goal
		play_sound goal.sample
	end

  # not used yet
	# def play_background_music
	# 	play_sound supporters.sample
	# end

  # def stop_backgroud_music
  # end

	def play_register_player_sound(n)
		play_sound "./media/player_#{n}.wav"
	end

  def match_start
    play_sound MATCH_START_SOUND
  end

  def match_end
    play_sound MATCH_END_SOUND
  end

  def play(tune)
    play_sound tune
  end

	private

	def play_sound(sound)
    sound = {:name => sound, :duration => 5} if sound.is_a?(String)
    omx.open sound[:name]
    sleep sound[:duration]
  end
end