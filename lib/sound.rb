class Sound
	def initialize(args)
		@goal = Dir.glob("./media/goal*.wav")
		@supporters = Dir.glob("./media/goal*.wav")
	end
	
	def get_random_goal_sound
		@goal.sample
	end

	def get_random_supporters_sound
		@supporters.sample
	end
end