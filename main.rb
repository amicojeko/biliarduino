require 'wiringpi'
require 'omxplayer'
require 'json'
require 'yaml'

Dir['lib/*.rb'].each do |file|
  require File.expand_path "../#{file}", __FILE__
end



class Table
  # TODO much of these constants should go in a configuration file
  PLAYERS      = 4 # when 2 players match you just register twice
  GOAL_DELAY   = 3
  DELAY        = 0.002
  OUTPUT_PINS  = {led: 7} # TODO the only output pin used now is for debugging glocked input state
  LED_STATES   = {on: 1, off: 0}
  STATES       = {idle: 0, registration: 1, start_match: 2, match: 3, end_match: 4}
  INPUT_PINS   = {
    goal_a: InputPin.new(0, pressed_value: 1, lock_timeframe: GOAL_DELAY),
    goal_b: InputPin.new(3, pressed_value: 1, lock_timeframe: GOAL_DELAY),
    start:  InputPin.new(4, pressed_value: 0) # no locking here
  }


  attr_reader   :gpio, :sound, :socket
  attr_accessor :state, :teams, :buttonstate, :ws

  PLAYERS.times { |n| attr_accessor "player_#{n}" }



  def initialize
    @gpio  = WiringPi::GPIO.new(WPI_MODE_PINS)
    @sound = Sound.new
    @teams = []
    init_inputs
    init_outputs
    unglock
  end

  def em_loop
    EM.run do
      @socket = ServerSocket.new(self)
      EM.add_periodic_timer DELAY, &method(:mainloop)
      EM.add_periodic_timer(3) { play_background_supporters }
    end
  end

  def mainloop
    open_new_connection_if_closed
    read_pins
    wait_for_start
    register_players
    start_match
    end_match
    check_input_pins
  end

  def open_new_connection_if_closed
    @socket = ServerSocket.new(self) if socket.closed? # TODO this could be moved into the server_socket class
  end

  STATES.each do |state, value|
    define_method "state_#{state}?" do
      self.state == value
    end
  end

  def set_state(state)
    self.state = STATES[state]
  end

  def close_match
    set_state(:end_match)
    # sound.reset_sounds
  end

  private

  def check_input_pins
    check_pressed INPUT_PINS[:start], message: 'match begins now', sound: :start_sound, on_state: :idle do |pin|
      set_state :registration
      unglock
    end
    check_pressed INPUT_PINS[:goal_a], message: 'goal team a', on_state: :match do |pin|
      unless pin.locked?
        sound.play_random_goal
        socket.update_score :a
        pin.lock
      end
    end
    check_pressed INPUT_PINS[:goal_b], message: 'goal team b', on_state: :match do |pin|
      unless pin.locked?
        sound.play_random_goal
        socket.update_score :b
        pin.lock
      end
    end
    reset_input_pins
  end

  def wait_for_start
    sound.play_once_idle_sound if state_idle?
  end

  def register_players
    if state_registration?
      clear_teams_and_players
      sound.play_register_sound
      PLAYERS.times do |n|
        player = "player_#{n}"
        unless send(player)
          sound.play_register_player_sound(n)
          get_player player until send(player)
        end
      end
      create_teams
      set_state :start_match
    end
  end

  def create_teams
    team_a = Team.new(:a)
    team_a.add_player player_0
    team_a.add_player player_1
    teams << team_a
    team_b = Team.new(:b)
    team_b.add_player player_2
    team_b.add_player player_3
    teams << team_b
  end

  def get_player(player)
    serial = RfidReader.open do
      read_pins
      check_pressed INPUT_PINS[:start], message: "skipping registration for #{player}", sound: :skip_registration do |pin|
        PLAYERS.times { |n| send "player_#{n}=", DummyPlayer.new }
        set_state :start_match
        return
      end
    end
    send "#{player}=", RegisteredPlayer.new(rfid: serial.reading)
    sound.play_player_registered
  end

  def start_match
    if state_start_match?
      set_state :match
      socket.start_match(teams)
      sound.play_match_start
      sound.play_background_supporters
    end
  end

  def end_match
    if state_end_match?
      sound.stop_supporters
      sound.play_match_end
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
        sound.send "play_#{opts[:sound]}" if opts[:sound]
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

  def play_background_supporters
    sound.play_background_supporters if state_match?
  end
end

t = Table.new
t.set_state :idle
t.em_loop