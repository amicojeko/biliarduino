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

    def match_closed?
      event == 'close_match'
    end

    def get_json(msg)
      JSON.parse(msg).first
    end
  end



  attr_reader :ws, :table

  def initialize(table)
    @table = table
    @ws    = build_socket
    add_events
  end

  # TODO isn't there a better way to check the state?
  # it probably would be better to handle reconnections
  # on the onclose event.
  def closed?
    ws.instance_variable_get('@state') == :closed
  end

  def build_socket
    WebSocket::EventMachine::Client.connect(uri: URL)
  end

  def add_events
    ws.onopen { puts "[EM] connected to #{URL}" }
    ws.onmessage do |msg, type|
      puts msg
      message = Message.new(msg, type)
      pong if message.ping?
      if message.match_closed?
        table.close_match
      end
    end
    ws.onclose { puts "[EM] disconnected #{URL}" }
  end

  def pong
    ws.send('["websocket_rails.pong", {}]')
  end

  def start_match(teams)
    trigger_event :start_match, start_match_json(teams)
  end

  def update_score(team_name)
    trigger_event :update_score, {team: team_name}.to_json
  end

  def trigger_event(event, data)
    ws.send %(["#{event}", {"data": #{data}}])
  end

  def start_match_json(teams)
    params = {}
    players  = teams.map {|t| t.players_as_json}.flatten
    players.each.with_index do |json, i|
      params["player_#{i+1}"] = json
    end
    params.to_json
  end
end

