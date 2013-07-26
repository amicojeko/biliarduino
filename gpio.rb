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
  GOAL_SOUND  = "horn.mp3"

  def initialize()
    @s = WiringPi::Serial.new('/dev/ttyAMA0',9600)
    @serialBuffer = ''
    @io = WiringPi::GPIO.new(WPI_MODE_PINS)
    @io.mode INPUT_PINS[:goal_a], INPUT
    @io.mode INPUT_PINS[:goal_b], INPUT
    @io.mode INPUT_PINS[:start], INPUT
    @io.mode OUTPUT_PINS[:led], OUTPUT
    @lock = false
  end

  def mainloop
    loop do
      #leggo lo stato degli input
      @buttonstate = @io.readAll

      #RFID CHECK
      while (@s.serialDataAvail > 0)
        @serialBuffer += @s.serialGetchar.chr
      end
      if @serialBuffer.size > 0
        p @serialBuffer
        @serialBuffer = ""
      end

      #INIZIO PARTITA
      if button_pressed? INPUT_PINS[:start]
        @lock = true
        led_on
        p "inizio partita"
        play_sound GOAL_SOUND
      end

      #GOAL SQUADRA A
      if button_pressed? INPUT_PINS[:goal_a]
        @lock = true
        led_on
        p "gol squadra 1"
        play_sound GOAL_SOUND
      end

      #GOAL SQUADRA B
      if button_pressed? INPUT_PINS[:goal_b]
        @lock = true
        led_on
        p "gol squadra 2"
        play_sound GOAL_SOUND
      end

      #TUTTI GLI INPUT A RIPOSO
      if INPUT_PINS.values.inject(1) {|r, key| r*@buttonstate[key] } == 1
        led_off
        @lock = false
      end

      sleep 0.002
    #LOOP END
    end
  #MAINLOOP METHOD END
  end

  def led_on
    led 1
  end

  def led_off
    led 0
  end

  private

  def button_pressed?(button)
    @buttonstate[button] == 0 && @lock == false #bottone premuto
  end

  def led(state)
    @io.write OUTPUT_PINS[:led], state
  end

  def play_sound(sound)
    fork { exec 'mpg123','-q', sound }
  end
end


t = Table.new
t.mainloop
