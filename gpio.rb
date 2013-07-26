require 'wiringpi'

class SerialPort
  def initialize
  end
end


class Player
  attr_accessor :id

  def initialize(id)
    @id = id
  end
end


class Team
  attr_accessor :id, :score

  def initialize(id)
    @id = id
    @score = 0
    @winner = false
  end

  def make_winner
    @winner = true
  end

  def winner?
    @winner
  end
end


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
      register_players
      start_match
      check_pressed INPUT_PINS[:start], :message => 'inizio partita', :sound => GOAL_SOUND, :on => :idle do
        self.state = STATES[:registration]
      end
      check_pressed INPUT_PINS[:goal_a], :message => 'gol squadra a', :sound => GOAL_SOUND, :on => :match do
        increase_score teams[0]
      end
      check_pressed INPUT_PINS[:goal_b], :message => 'gol squadra b', :sound => GOAL_SOUND, :on => :match do
        increase_score teams[1]
      end
      reset_pins
      sleep 0.002
    end
  end

  STATES.each do |state, value|
    define_method "state_#{state}?" do
      self.state == value
    end
  end

  private

  def increase_score(team)
    team.score += 1
    if team.score >= GOALS
      team.make_winner
      p "the winner is team #{team.id}"
      self.state = STATES[:end_match]
    end
  end

  def register_players
    if state_registration?
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

  def start_match
    if state_start_match?
      p "match has started"
      self.state = STATES[:match]
    end
  end

  def end_match
    p "match is over"
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

  def get_player(player)
    while @serial.serialDataAvail > 0
      @serialBuffer += @serial.serialGetchar.chr
    end
    if @serialBuffer.size > 0
      send "#{player}=", Player.new(@serialBuffer)
      @serialBuffer = ''
    end
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
    INPUT_PINS.values.inject(1) { |r, value|
      r * @buttonstate[value] 
    } == 1
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
end

t = Table.new
t.state = Table::STATES[:idle]
t.mainloop
