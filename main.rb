require 'wiringpi'

require File.expand_path('../lib/player', __FILE__)
require File.expand_path('../lib/team', __FILE__)

class Game
  def initialize
  end
end



class Table
  GOALS       = 8
  PLAYERS     = 4
  GOLDEN_GOAL = false
  INPUT_PINS  = {goal_a: 0, goal_b: 3, start: 4}
  OUTPUT_PINS = {led: 7}
  LED_STATES  = {:on => 1, :off => 0}
  GOAL_SOUND  = 'horn.mp3'
  STATES      = {idle: 0, registration: 1, start_match: 2, match: 3, end_match: 4}


  attr_accessor :state, :teams

  PLAYERS.times { |n| attr_accessor "player_#{n}" }


  def initialize
    @io = WiringPi::GPIO.new(WPI_MODE_PINS)
    @teams = []
    init_serial
    init_inputs
    init_outputs
    unlock
  end

  def mainloop
    loop do
      init_pins
      wait_for_start
      register_players
      start_match
      end_match
      check_buttons
      sleep 0.002
    end
  end

  STATES.each do |state, value|
    define_method "state_#{state}?" do
      self.state == value
    end
  end

  private

  def check_buttons
    check_pressed INPUT_PINS[:start], :message => 'match begins now', :sound => GOAL_SOUND, :on => :idle do
      self.state = STATES[:registration]
    end
    check_pressed INPUT_PINS[:goal_a], :message => 'goal team a', :sound => GOAL_SOUND, :on => :match do
      increase_score teams[0]
    end
    check_pressed INPUT_PINS[:goal_b], :message => 'goal team b', :sound => GOAL_SOUND, :on => :match do
      increase_score teams[1]
    end
    reset_pins
  end

  def wait_for_start
    if state_idle? and !@done
      p "idle - please push start button"
      @done = true
    end
  end

  def register_players
    if state_registration?
      clear_players
      clear_teams
      p 'register players'
      PLAYERS.times do |n|
        p "player #{n}:"
        player = "player_#{n}"
        get_player player until send(player)
      end
      teams << Team.new(:a)
      teams << Team.new(:b)
      self.state = STATES[:start_match]
      puts self.state
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
    team.score += 1
    if team.score >= GOALS
      team.make_winner
      p "the winner is team #{team.id}"
      self.state = STATES[:end_match]
    end
  end

  def start_match
    if state_start_match?
      p "match has started"
      self.state = STATES[:match]
    end
  end

  def end_match
    if state_end_match?
      p "match is over"
      self.state = STATES[:idle]
      @done = false
    end
  end


  def init_serial
    @serial = WiringPi::Serial.new('/dev/ttyAMA0',9600)
    @serialBuffer = ''
  end

  def init_pins
    @buttonstate = @io.readAll
    init_inputs
    init_outputs
  end

  def init_inputs
    INPUT_PINS.values.each { |pin| @io.mode(pin, INPUT) }
  end

  def init_outputs
    OUTPUT_PINS.values.each {|pin| @io.mode(pin, OUTPUT) }
  end

  def check_pressed(pin, opts)
    if button_pressed? pin
      if !opts[:on] or opts[:on] && send("state_#{opts[:on]}?")
        lock
        led :on
        p opts[:message]
        play_sound opts[:sound]
        yield if block_given?
      end
    end
  end

  def all_button_released?
    INPUT_PINS.values.inject(1) { |r, value| r * @buttonstate[value] } == 1
  end

  def button_pressed?(button)
     !locked? and @buttonstate[button] == 0 # bottone premuto
  end

  def reset_pins
     if all_button_released?
      led :off
      unlock
    end
  end

  def led(state)
    @io.write OUTPUT_PINS[:led], LED_STATES[state]
  end

  def play_sound(sound)
    fork { exec 'mpg123','-q', sound }
  end

  def lock
    @lock = true
  end

  def unlock
    @lock = false
  end

  def locked?
    @lock
  end

  def clear_teams
    self.teams = []
  end

  def clear_players
    PLAYERS.times {|n| send "player_#{n}=", nil}
  end
end

t = Table.new
t.state = Table::STATES[:idle]
t.mainloop
