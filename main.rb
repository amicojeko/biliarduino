require 'wiringpi'

require File.expand_path('../lib/player', __FILE__)
require File.expand_path('../lib/team', __FILE__)

class Table
  DELAY       = 0.002
  GOALS       = 8
  PLAYERS     = 4
  GOLDEN_GOAL = false

  INPUT_PINS  = {goal_a: 0, goal_b: 3, start: 4}
  OUTPUT_PINS = {led: 7}
  LED_STATES  = {:on => 1, :off => 0}
  STATES      = {idle: 0, registration: 1, start_match: 2, match: 3, end_match: 4}

  IDLE_SOUND         = 'media/idle.wav'
  GOAL_SOUND         = 'media/horn.mp3'
  GOAL_SOUND_A       = 'media/goal_team_a.wav'
  GOAL_SOUND_B       = 'media/goal_team_b.wav'
  REGISTER_SOUND     = 'media/register.wav'
  MATCH_START_SOUND  = 'media/match_start.wav'
  MATCH_END_SOUND    = 'media/match_end.wav'

  IDLE_VIDEO  = 'media/Holly\ e\ Benji.flv'



  attr_reader   :gpio
  attr_accessor :state, :teams

  PLAYERS.times { |n| attr_accessor "player_#{n}" }


  def initialize
    @gpio  = WiringPi::GPIO.new(WPI_MODE_PINS)
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

  def check_buttons
    check_pressed INPUT_PINS[:start], :message => 'match begins now', :sound => GOAL_SOUND, :on => :idle do
      set_state :registration
    end
    check_pressed INPUT_PINS[:goal_a], :message => 'goal team a', :sound => GOAL_SOUND_A, :on => :match do
      increase_score teams[0]
    end
    check_pressed INPUT_PINS[:goal_b], :message => 'goal team b', :sound => GOAL_SOUND_B, :on => :match do
      increase_score teams[1]
    end
    reset_pins
  end

  # TO_DELETE: cagata fatta per debuggare il say
  # def p(param)
  #   say(param)
  # end

  def wait_for_start
    if state_idle? and !@done
      #play_video IDLE_VIDEO
      #fixme: se mettiamo il video si incasina un po tutto (non riesco a sopparlo :) )
      p_once "idle - please push start button"
      play_sound IDLE_SOUND
      @done = true
    end
  end

  def register_players
    if state_registration?
      #kill @video_pid #non funziona!!
      clear_players
      clear_teams
      p 'register players'
      play_sound REGISTER_SOUND
      PLAYERS.times do |n|
        p "player #{n}:"
        play_sound "media/player_#{n}.wav"
        player = "player_#{n}"
        get_player player until send(player)
      end
      teams << Team.new(:a)
      teams << Team.new(:b)
      set_state :start_match
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
    #FIXME: non so se va qua, è la procedura per fare la foto
    get_snapshot(team.id)
    if team.score >= GOALS
      team.make_winner
      p "the winner is team #{team.id}"
      play_sound "media/winner_team_#{team.id}.wav"
      set_state :end_match
    end
  end

  def start_match
    if state_start_match?
      p "match has started"
      play_sound MATCH_START_SOUND
      set_state :match
    end
  end

  def end_match
    if state_end_match?
      p "match is over"
      play_sound MATCH_END_SOUND
      #TODO: dare il risultato finale
      #p "the final result is team a: #{teams.first.score}, team b: #{teams.last.score}"
      set_state :idle
    end
  end


  def init_serial
    @serial = WiringPi::Serial.new('/dev/ttyAMA0',9600)
    @serialBuffer = ''
  end

  def init_pins
    @buttonstate = gpio.readAll
    init_inputs
    init_outputs
  end

  def init_inputs
    INPUT_PINS.values.each { |pin| gpio.mode(pin, INPUT) }
  end

  def init_outputs
    OUTPUT_PINS.values.each {|pin| gpio.mode(pin, OUTPUT) }
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
    gpio.write OUTPUT_PINS[:led], LED_STATES[state]
  end

  def play_sound(sound)
    #@sound_pid = fork { exec 'mpg123','-q', sound }
    #@sound_pid = fork { exec 'omxplayer -o local ' + sound }
    #trovo che omxplayer sia piu performante di mpg123, e legge anche i wav, cosa che mpg123 non fa
    #qui ho messo system perché alcuni suoni devono essere bloccanti (come le voci di inizio partita ecc...)
    #e altri no (Come il suono del gol)
    #TODO: aggiungere un parametro per decidere se il suono è bloccante o meno, o almeno trovare il modo di evitare che i suoni si sovrappongano
    system 'bin/play_media ' + sound
  end

  def play_video(video)
    @video_pid = fork { exec 'bin/play_media ' + video }
  end

  def say(text)
    #@say_pid = fork { exec 'echo "' + text + '" | festival --tts'}
    @say_pid = fork { exec 'espeak "' + text + '"'}
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

  def kill(pid)
    system 'kill -9 ' + pid.to_s
  end

  def get_snapshot(camera)
    fork { exec "fswebcam -r 640x480 -d /dev/video0 'snapshots/webcam#{Time.now.to_i}.jpg'"}    
  end

  def p_once(message)
    unless @__printed
      p message
      @__printed = true
    end
  end
end

t = Table.new
t.set_state :idle
t.mainloop
