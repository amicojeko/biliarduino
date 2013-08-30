require 'wiringpi'
require 'omxplayer'

require File.expand_path('../lib/player', __FILE__)
require File.expand_path('../lib/team',   __FILE__)




class InputPin
  # lock_time is used to lock only this input for consecutive press events, while glock_time locks the inputs globally for given seconds
  attr_reader :pin, :pressed_value, :lock_time, :locked

  def initialize(pin, opts)
    @pin           = pin
    @lock_time     = opts[:lock_time]
    @pressed_value = opts[:pressed_value]
  end

  def locked?
    locked
  end

  def lock
    @locked = true
  end

  def unlock
    @locked = false
  end
end




class Table
  # TODO much of these constants should go in a configuration file
  MAX_GOALS   = 4
  PLAYERS     = 4
  GOAL_DELAY  = 3
  DELAY       = 0.002
  GOLDEN_GOAL = false
  OUTPUT_PINS = {led: 7} # TODO the only output pin used now is for debugging glocked input state
  LED_STATES  = {:on => 1, :off => 0}
  STATES      = {idle: 0, registration: 1, start_match: 2, match: 3, end_match: 4}
  INPUT_PINS  = {
    goal_a: InputPin.new(0, :pressed_value => 1, :glock_time => 3),
    goal_b: InputPin.new(3, :pressed_value => 1, :glock_time => 3),
    start:  InputPin.new(4, :pressed_value => 0) # no locking here
  }

  IDLE_SOUND        = {:name => 'media/idle.wav'          , :duration => 2}
  START_SOUND       = {:name => 'media/horn.mp3'          , :duration => 2}
  GOAL_SOUND_A      = {:name => 'media/goal_team_a.wav'   , :duration => 2}
  GOAL_SOUND_B      = {:name => 'media/goal_team_b.wav'   , :duration => 2}
  REGISTER_SOUND    = {:name => 'media/register.wav'      , :duration => 2}
  MATCH_START_SOUND = {:name => 'media/match_start.wav'   , :duration => 2}
  MATCH_END_SOUND   = {:name => 'media/match_end.wav'     , :duration => 2}
  WINNER_TEAM_A     = {:name => "media/winner_team_a.wav" , :duration => 2}
  WINNER_TEAM_B     = {:name => "media/winner_team_b.wav" , :duration => 2}
  IDLE_VIDEO        = 'media/Holly\ e\ Benji.flv'


  attr_reader   :gpio
  attr_accessor :state, :teams, :last_goal_at
  PLAYERS.times { |n| attr_accessor "player_#{n}" }


  def initialize
    @gpio  = WiringPi::GPIO.new(WPI_MODE_PINS)
    @omx   = Omxplayer.instance
    @teams = []
    set_goal_time
    init_serial
    init_inputs
    init_outputs
    unglock
  end

  def mainloop
    loop do
      read_pins
      # wait_for_start
      # register_players
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
    @__printed = false
    self.state = STATES[state]
  end

  private

  def check_input_pins
    check_pressed INPUT_PINS[:start], :message => 'match begins now', :sound => START_SOUND, :on_state => :idle do
      set_state :registration
    end
    check_pressed INPUT_PINS[:goal_a], :message => 'goal team a', :sound => GOAL_SOUND_A, :on_state => :match do
      increase_score teams[0]
    end
    check_pressed INPUT_PINS[:goal_b], :message => 'goal team b', :sound => GOAL_SOUND_B, :on_state => :match do
      increase_score teams[1]
    end
    reset_input_pins
  end

  def wait_for_start
    if state_idle? and !@started
      # fixme: se mettiamo il video si incasina un po tutto (non riesco a sopparlo :) )
      # play_video IDLE_VIDEO
      debug_once "idle - please push start button"
      play_sound IDLE_SOUND
      @started = true
    end
  end

  def register_players
    if state_registration?
      clear_teams_and_players
      debug 'register players'
      play_sound REGISTER_SOUND
      PLAYERS.times do |n|
        debug "player #{n}:"
        play_sound :name => "media/player_#{n}.wav", :duration => 2 # TODO extract constants for these sounds
        player = "player_#{n}"
        get_player player until send(player)
      end
      teams << Team.new(:a)
      teams << Team.new(:b)
      set_state :start_match
      debug self.state
    end
  end

  def get_player(player)
    while @serial.serialDataAvail > 0
      @serialBuffer += @serial.serialGetchar.chr
    end
    if @serialBuffer.size > 0
      send "#{player}=", Player.new(@serialBuffer)
      @serialBuffer = ''
    end
  end

  def increase_score(team)
    unless goal_already_registered?
      set_goal_time
      team.score += 1
      get_snapshot team
      debug "team #{team.name} score: #{team.score}"
      if team.score >= MAX_GOALS
        finalize_match(team)
      end
      unglock # trouble...
    else
      puts 'goal still already registered'
    end
  end

  def start_match
    unless $A
      set_state :start_match # TODO remove
      teams << Team.new(:a)
      teams << Team.new(:b)
      $A = true
    end
    if state_start_match?
      debug "match has started"
      play_sound MATCH_START_SOUND
      set_state :match
    end
  end

  def end_match
    if state_end_match?
      debug "match is over"
      play_sound MATCH_END_SOUND
      # TODO: dare il risultato finale
      debug "the final result is team a: #{teams.first.score}, team b: #{teams.last.score}"
      set_state :idle
    end
  end

  def init_serial
    @serial = WiringPi::Serial.new('/dev/ttyAMA0',9600)
    @serialBuffer = ''
  end

  def read_pins
    @buttonstate = gpio.readAll
    # p @buttonstate
  end

  def init_inputs
    INPUT_PINS.values.each { |pin| gpio.mode(pin.pin, INPUT) }
  end

  def init_outputs
    OUTPUT_PINS.values.each {|pin| gpio.mode(pin, OUTPUT) }
  end

  def check_pressed(pin, opts)
    if pin_pressed? pin
      # true when state is missing (callback happens always), or is correct for this event
      if !opts[:on_state] or opts[:on_state] && send("state_#{opts[:on_state]}?")
        glock
        debug opts[:message]
        play_sound opts[:sound]
        yield if block_given?
      end
    end
  end

  def any_pin_pressed?
    INPUT_PINS.values.inject false do |bool, pin|
      bool ||= @buttonstate[pin.pin] == pin.pressed_value
    end
  end

  def pin_pressed?(pin)
    !glocked? and @buttonstate[pin.pin] == pin.pressed_value
  end

  def reset_input_pins
     unless any_pin_pressed?
      unglock
    end
  end

  def led(state)
    gpio.write OUTPUT_PINS[:led], LED_STATES[state]
  end

  # glock is global lock, locks all inputs. Each input can have its own lock, and its own input unlocker
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

  def kill(pid)
    system "kill -9 #{pid}"
  end

  # FIXME prende un parametro, ma non viene usato
  def get_snapshot(team)
    camera = team.id
    fork { exec "fswebcam -r 640x480 -d /dev/video0 'snapshots/webcam_#{Time.now.to_i}.jpg'"}
  end

  def debug_once(message)
    unless @__printed
      debug message
      @__printed = true
    end
  end

  def set_goal_time
    self.last_goal_at = Time.now
  end

  def goal_already_registered?
    enough_time_passed = last_goal_at + 3 >= Time.now
    unglock if enough_time_passed
    enough_time_passed
  end

  private

  def debug(message)
    p message
  end

  def finalize_match(team)
    team.set_winner
    debug "the winner is team #{team.name}"
    play_sound sound self.class.const_get "WINNER_TEAM_#{team.name}"
    set_state :end_match
  end

  def play_sound(sound)
    @omx.open(sound[:name])
    sleep sound[:duration]
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
