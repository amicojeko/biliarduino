

require 'wiringpi'
require 'omxplayer'

require File.expand_path('../lib/player', __FILE__)
require File.expand_path('../lib/team',   __FILE__)




class InputPin
  # lock_timeframe is used to lock only this input for consecutive press events, while glock_timeframe locks the inputs globally for given seconds
  attr_reader :pin, :pressed_value, :lock_timeframe, :locked, :locked_at

  def initialize(pin, opts)
    @pin            = pin
    @lock_timeframe = opts.fetch(:lock_timeframe, 0)
    @pressed_value  = opts.fetch(:pressed_value, 0)
  end

  # TODO refactor this shit
  def locked?
    if locked
      if locked_at + lock_timeframe >= Time.now
        true
      else
        false
      end
    else
      false
    end
  end

  def lock
    @locked_at = Time.now
    @locked = true
  end

  def unlock
    @locked = false
  end
end




class Table
  # TODO much of these constants should go in a configuration file
  MAX_GOALS    = 4
  PLAYERS      = 4
  GOAL_DELAY   = 2
  DELAY        = 0.002
  SERIAL_DELAY = 0.02
  GOLDEN_GOAL  = false
  OUTPUT_PINS  = {led: 7} # TODO the only output pin used now is for debugging glocked input state
  LED_STATES   = {:on => 1, :off => 0}
  STATES       = {idle: 0, registration: 1, start_match: 2, match: 3, end_match: 4}
  INPUT_PINS   = {
    goal_a: InputPin.new(0, :pressed_value => 1, :lock_timeframe => GOAL_DELAY),
    goal_b: InputPin.new(3, :pressed_value => 1, :lock_timeframe => GOAL_DELAY),
    start:  InputPin.new(4, :pressed_value => 0) # no locking here
  }

  IDLE_SOUND        = {:name => 'media/idle.wav'         , :duration => 2}
  START_SOUND       = {:name => 'media/horn.mp3'         , :duration => 1}
  GOAL_SOUND_A      = {:name => 'media/goal_team_a.wav'  , :duration => 1}
  GOAL_SOUND_B      = {:name => 'media/goal_team_b.wav'  , :duration => 1}
  REGISTER_SOUND    = {:name => 'media/register.wav'     , :duration => 2}
  MATCH_START_SOUND = {:name => 'media/match_start.wav'  , :duration => 1}
  MATCH_END_SOUND   = {:name => 'media/match_end.wav'    , :duration => 1}
  WINNER_TEAM_A     = {:name => "media/winner_team_a.wav", :duration => 1}
  WINNER_TEAM_B     = {:name => "media/winner_team_b.wav", :duration => 1}
  IDLE_VIDEO        = 'media/Holly\ e\ Benji.flv'


  attr_reader   :gpio, :omx
  attr_accessor :state, :teams, :last_goal_at
  PLAYERS.times { |n| attr_accessor "player_#{n}" }


  def initialize
    @gpio  = WiringPi::GPIO.new(WPI_MODE_PINS)
    @omx   = Omxplayer.instance
    @teams = []
    init_serial
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
    end
    check_pressed INPUT_PINS[:goal_a], :message => 'goal team a', :on_state => :match do |pin|
      unless pin.locked?
        increase_score(teams[0])
        pin.lock
      end
    end
    check_pressed INPUT_PINS[:goal_b], :message => 'goal team b', :on_state => :match do |pin|
      unless pin.locked?
        increase_score(teams[1])
        pin.lock
      end
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
      set_state :registration # remove
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
    end
  end

  def get_player(player)
    while @serial.serialDataAvail > 0
      @serialBuffer += @serial.serialGetchar.chr
      sleep SERIAL_DELAY
    end
    if @serialBuffer.size > 0
      code = sanitizeSerialBufferString
      debug "#{player}: {code}"
      send "#{player}=", Player.new(code)
      @serialBuffer = ''
    end
  end

  def increase_score(team)
    team.score += 1
    get_snapshot team
    debug "team #{team.name} score: #{team.score}"
    play_sound self.class.const_get("GOAL_SOUND_#{team.name}")
    if team.score >= MAX_GOALS
      finalize_match team
    end
    unglock
  end

  def start_match
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
        play_sound opts[:sound] if opts[:sound]
        yield pin if block_given?
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
    p message
  end

  # FIXME prende un parametro, ma non viene usato
  def get_snapshot(team)
    camera = team.id
    fork { exec "fswebcam -r 640x480 -d /dev/video0 'snapshots/webcam_#{Time.now.to_i}.jpg'"}
  end

  def finalize_match(team)
    team.set_winner
    debug "the winner is team #{team.name}"
    play_sound self.class.const_get "WINNER_TEAM_#{team.name}"
    set_state :end_match
  end

  def play_sound(sound)
    omx.open sound[:name]
    sleep sound[:duration] || 0
  end

  def play_video(video)
    # TODO temporarily disabled
    # @video_pid = fork { exec 'bin/play_media ' + video }
  end

  def say(text)
    # @say_pid = fork { exec 'echo "' + text + '" | festival --tts'}
    @say_pid = fork { exec 'espeak "' + text + '"'}
  end

  # TODO this is rather crappy
  def sanitizeSerialBufferString
    begin
      @serialBuffer.split("\u0002")[1].split("\u0003")[0]
    rescue
      raise "could not read data correctly from serial buffer"
    end
  end
end

t = Table.new
t.set_state :idle
t.mainloop
