require 'wiringpi'
require 'omxplayer'

Dir['lib/*.rb'].each do |file|
  require File.expand_path "../#{file}", __FILE__
end

$debug = true if ARGV.delete('-d')



class Table
  # TODO much of these constants should go in a configuration file
  MAX_GOALS    = 8
  PLAYERS      = 4 # when 2 players match you just register twice
  GOAL_DELAY   = 3
  DELAY        = 0.002
  GOLDEN_GOAL  = true
  OUTPUT_PINS  = {led: 7} # TODO the only output pin used now is for debugging glocked input state
  LED_STATES   = {:on => 1, :off => 0}
  STATES       = {idle: 0, registration: 1, start_match: 2, match: 3, end_match: 4}
  INPUT_PINS   = {
    goal_a: InputPin.new(0, :pressed_value => 1, :lock_timeframe => GOAL_DELAY),
    goal_b: InputPin.new(3, :pressed_value => 1, :lock_timeframe => GOAL_DELAY),
    start:  InputPin.new(4, :pressed_value => 0) # no locking here
  }


  # TODO put all this stuff in the sound library
  START_SOUND       = {:name => 'media/horn.mp3'         , :duration => 1}
  WINNER_TEAM_A     = {:name => "media/winner_team_a.wav", :duration => 1} # custom team
  WINNER_TEAM_B     = {:name => "media/winner_team_b.wav", :duration => 1} # custom team
  PLAYER_REGISTERED = {:name => 'media/beep-7.wav',        :duration => 1}
  SKIP_REGISTRATION = {:name => 'media/beep-7.wav',        :duration => 1}



  attr_reader   :gpio, :sound, :social
  attr_accessor :state, :teams, :buttonstate

  PLAYERS.times { |n| attr_accessor "player_#{n}" }



  def initialize
    @gpio   = WiringPi::GPIO.new(WPI_MODE_PINS)
    @sound  = Sound.new
    @social = Social.new
    @teams  = []
    init_inputs
    init_outputs
    unglock
  end

  def mainloop
    loop do
      read_pins
      wait_for_start
      register_players
      start_match
      end_match
      check_input_pins
      sleep DELAY
    end
  end

  STATES.each do |state, value|
    define_method "state_#{state}?" do
      self.state == value
    end
  end

  def set_state(state)
    @__flushed = false
    self.state = STATES[state]
  end

  private

  def check_input_pins
    check_pressed INPUT_PINS[:start], :message => 'match begins now', :sound => START_SOUND, :on_state => :idle do |pin|
      set_state :registration
      unglock
    end
    check_pressed INPUT_PINS[:goal_a], :message => 'goal team a', :on_state => :match do |pin|
      unless pin.locked?
        increase_score teams[0]
        pin.lock
      end
    end
    check_pressed INPUT_PINS[:goal_b], :message => 'goal team b', :on_state => :match do |pin|
      unless pin.locked?
        increase_score teams[1]
        pin.lock
      end
    end
    reset_input_pins
  end

  def wait_for_start
    if state_idle? and !@started
      debug_once "idle - please push start button"
      sound.play_idle_sound
      @started = true
    end
  end

  def register_players
    if state_registration?
      clear_teams_and_players
      debug 'register players'
      PLAYERS.times do |n|
        player = "player_#{n}"
        unless send(player)
          sound.play_register_player_sound(n)
          get_player player until send(player)
        end
      end
      teams << Team.new(:a)
      teams << Team.new(:b)
      set_state :start_match
    end
  end

  def get_player(player)
    debug "waiting for #{player}"
    serial = RfidReader.open do
      read_pins
      check_pressed INPUT_PINS[:start], :message => "skipping registration for #{player}", :sound => SKIP_REGISTRATION do |pin|
        4.times {|n| send "player_#{n}=", n}
        set_state :start_match
        return
      end
    end
    debug "#{player}: #{serial.reading}"
    send "#{player}=", Player.new(serial.reading)
    play_sound PLAYER_REGISTERED
  end

  def increase_score(team)
    team.score += 1
    # TODO: get a photo of the scoring team
    # get_snapshot team

    debug "team #{team.name} score: #{team.score}, team #{other_team(team).name} score: #{other_team(team).score}"
    sound.play_random_goal
    if team.score >= MAX_GOALS
      unless GOLDEN_GOAL
        finalize_match team
      else
        finalize_match(team) if team.score >= other_team(team).score + 2
      end
    end
    unglock
  end

  def other_team(team)
    teams.detect {|t| t.code != team.code}
  end

  def start_match
    if state_start_match?
      sound.match_start
      social.tweet "A new match has started at #{Time.now}!"
      set_state :match
    end
  end

  def end_match
    if state_end_match?
      sound.match_end
      debug "the final result is team a: #{teams.first.score}, team b: #{teams.last.score}"
      social.tweet "The match is over. The final result is Blue Team: #{teams.first.score} - Red Team: #{teams.last.score} at #{Time.now}!"
      set_state :idle
    end
  end

  def read_pins
    self.buttonstate = gpio.readAll
  end

  def init_inputs
    INPUT_PINS.values.each do |pin|
      gpio.mode  pin.pin, INPUT
      gpio.write pin.pin, 0
    end
  end

  def init_outputs
    OUTPUT_PINS.values.each {|pin| gpio.mode pin, OUTPUT }
  end

  # it's our responsibility to unglock the pins
  def check_pressed(pin, opts)
    if pin_pressed? pin
      # true when state is missing (callback happens always), or is correct for this event
      if !opts[:on_state] or opts[:on_state] && send("state_#{opts[:on_state]}?")
        glock
        debug opts[:message] || "#{pin} pressed"
        play_sound opts[:sound] if opts[:sound]
        yield pin if block_given?
      end
    end
  end

  def any_pin_pressed?
    INPUT_PINS.values.inject false do |bool, pin|
      bool ||= buttonstate[pin.pin] == pin.pressed_value
    end
  end

  def pin_pressed?(pin)
    !glocked? and buttonstate[pin.pin] == pin.pressed_value
  end

  def reset_input_pins
    unglock unless any_pin_pressed?
  end

  def led(state)
    gpio.write OUTPUT_PINS[:led], LED_STATES[state]
  end

  # glock is global lock, locks all inputs. Each input can have its own lock
  def glock
    led :on
    @glock = true
  end

  def unglock
    led :off
    @glock = false
  end

  def glocked?
    @glock
  end

  def clear_teams_and_players
    self.teams = []
    PLAYERS.times {|n| send "player_#{n}=", nil}
  end

  def debug_once(message)
    unless @__flushed
      debug message
      @__flushed = true
    end
  end

  private

  def debug(message)
    p message if $debug
  end

  # FIXME prende un parametro, ma non viene usato
  def get_snapshot(team)
    camera = team.code
    fork { exec "fswebcam -r 640x480 -d /dev/video0 'snapshots/webcam_#{Time.now.to_i}.jpg'"}
  end

  def finalize_match(team)
    team.set_winner
    debug "the winner is team #{team.name}"
    play_sound self.class.const_get "WINNER_TEAM_#{team.name}"
    set_state :end_match
  end

  def play_sound(tune)
    sound.play tune
  end

  def play_video(video)
    # TODO temporarily disabled
    # @video_pid = fork { exec 'bin/play_media ' + video }
  end

  def say(text)
    # @say_pid = fork { exec 'echo "' + text + '" | festival --tts'}
    @say_pid = fork { exec 'espeak "' + text + '"'}
  end
end

t = Table.new
t.set_state :idle
t.mainloop


