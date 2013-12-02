require 'yaml'
require 'json'
require 'websocket-eventmachine-client'

SERVER_CONFIG = YAML.load_file File.expand_path('../../config/server.yml', __FILE__)



class ServerSocket
  URL = "#{SERVER_CONFIG['protocol']}://#{SERVER_CONFIG['domain']}:#{SERVER_CONFIG['port'] || 80}/websocket"

  class Message
    attr_reader :event, :data, :type, :json

    def initialize(msg, type)
      @type  = type
      @json  = get_json(msg)
      @event = json.first
      @data  = json.last['data']
    end

    def ping?
      event == 'websocket_rails.ping'
    end

    def get_json(msg)
      JSON.parse(msg).first
    end
  end



  attr_reader :ws

  def initialize
    @ws = build_socket
    add_events
  end

  def build_socket
    WebSocket::EventMachine::Client.connect(uri: URL)
  end

  def add_events
    ws.onopen { puts "[EM] connected to #{URL}" }
    ws.onmessage do |msg, type|
      message = Message.new(msg, type)
      pong if message.ping?
    end
    ws.onclose { puts "[EM] disconnected #{URL}" }
  end

  def pong
    ws.send('["websocket_rails.pong", {}]')
  end

  def start_match(teams)
    trigger_event :start_match, start_match_json(teams)
  end

  def update_match(teams)
    trigger_event :update_match, update_match_json(teams)
  end

  def close_match(teams)
    trigger_event :close_match, close_match_json(teams)
  end

  def trigger_event(event, data)
    ws.send %(["#{event}", {"data": #{data}}}])
  end

  def start_match_json(teams)
    params = {}
    codes  = teams.map {|t| t.player_codes}.flatten
    codes.each.with_index do |code, i|
      params["player_#{i+1}"] = code
    end
    params.to_json
  end

  def update_match_json(teams)
    {
      team_a_score: teams.first.score,
      team_b_score: teams.last.score
    }.to_json
  end
  alias close_match_json update_match_json
end

