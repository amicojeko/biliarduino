require 'wiringpi'

class SerialPort
  def initialize
  end
end

class Player
  def initialize
  end
end

class Team
  def initialize
  end
end

class Game
  def initialize
  end
end

class Table
  INPUT_PINS  = {goal_a: 0, goal_b: 3, start: 4}
  OUTPUT_PINS = {led: 7}
  LED_STATES  = {:on => 1, :off => 0}
  GOAL_SOUND  = 'horn.mp3'

  def initialize
    @io = WiringPi::GPIO.new(WPI_MODE_PINS)
    init_serial
    init_inputs
    start_outputs
    unlock
  end

  def mainloop
    loop do
      @buttonstate = @io.readAll
      #RFID CHECK
      check_serial
      #INIZIO PARTITA
      check_pressed INPUT_PINS[:start], :message => 'inizio partita', :sound => GOAL_SOUND
      #GOAL SQUADRA A
      check_pressed INPUT_PINS[:goal_a], :message => 'gol squadra a', :sound => GOAL_SOUND
      #GOAL SQUADRA B
      check_pressed INPUT_PINS[:goal_b], :message => 'gol squadra b', :sound => GOAL_SOUND
      #TUTTI GLI INPUT A RIPOSO
      reset_pins
      sleep 0.002
    end
  end

  private

  def init_serial
    @serial = WiringPi::Serial.new('/dev/ttyAMA0',9600)
    @serialBuffer = ''
  end

  def init_inputs
    INPUT_PINS.values.each { |pin| @io.mode pin, INPUT }
  end

  def init_outputs
    OUTPUT_PINS.each {|pin| @io.mode pin,  OUTPUT }
  end

  def check_serial
    while @serial.serialDataAvail > 0
      @serialBuffer += @serial.serialGetchar.chr
    end
    if @serialBuffer.size > 0
      p @serialBuffer
      @serialBuffer = ''
    end
  end

  def check_pressed(pin, opts)
    if button_pressed? INPUT_PINS[:goal_a]
      lock
      led :on
      p opts[:message]
      play_sound opts[:sound]
    end
  end

  def all_button_depressed?
    INPUT_PINS.values.inject(1) { |r, value| r * @buttonstate[value] } == 1
  end

  def button_pressed?(button)
     !locked? and @buttonstate[button] == 0 # bottone premuto
  end

  def reset_pins
     if all_button_depressed?
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
t.mainloop
