require 'omxplayer'

class Sound

  IDLE_SOUND        = {:name => 'media/idle.wav'         , :duration => 2}
  START_SOUND       = {:name => 'media/horn.mp3'         , :duration => 1}
  GOAL_SOUND_A      = {:name => 'media/goal_team_a.wav'  , :duration => 1} # custom team
  GOAL_SOUND_B      = {:name => 'media/goal_team_b.wav'  , :duration => 1} # custom team
  REGISTER_SOUND    = {:name => 'media/register.wav'     , :duration => 2}
  MATCH_START_SOUND = {:name => 'media/match_start.wav'  , :duration => 1}
  MATCH_END_SOUND   = {:name => 'media/match_end.wav'    , :duration => 1}
  WINNER_TEAM_A     = {:name => "media/winner_team_a.wav", :duration => 1} # custom team
  WINNER_TEAM_B     = {:name => "media/winner_team_b.wav", :duration => 1} # custom team
  PLAYER_REGISTERED = {:name => 'media/beep-7.wav',        :duration => 1}
  SKIP_REGISTRATION = {:name => 'media/beep-7.wav',        :duration => 1}


	def initialize
		@omx   = Omxplayer.instance
		@goal = Dir.glob("./media/goal*.wav")
		@supporters = Dir.glob("./media/goal*.wav")
	end

	def play_idle_sound
		play_sound IDLE_SOUND[:name]
	end

	def play_register_sound
		play_sound REGISTER_SOUND[:name]
	end

	def play_goal_sound
		play_sound @goal.sample
	end

	def play_background_music
		play_sound @supporters.sample
	end

	def play_register_player_sound(n)
		play_sound "./media/player_#{n}.wav"
	end

	def stop_backgroud_music
	end


	private

	def play_sound(sound)
    omx.open sound
    sleep 5
  end
end