require 'yaml'
require 'json'
require 'web_socket'

SERVER_CONFIG = YAML.load_file File.expand_path('../../config/server.yml', __FILE__)

class Server
  attr_reader :client

  def initialize
    connect
  end

  def start_match(teams)
    send_message :start_match, get_player_params(teams)
  end

  def close_match(teams)
    send_message :close_match, get_score_params(teams)
  end

  def update_match(teams)
    send_message :update_match, get_score_params(teams)
  end

  def send_message(event, payload, opts={})
    retries = opts.fetch(:retries, 3)
    begin
      client.send %(["#{event}", {"data": #{payload.to_json}}])
    rescue => e
      log_error e
      if retries.size > 0
        connect
        send_message(event, payload, retries: retries-1)
      end
    end
  end

  def get_player_params(teams)
    params = {}
    codes  = teams.map {|t| t.player_codes}.flatten
    codes.each.with_index do |code, i|
      params["player_#{i+1}"] = code
    end
    params
  end

  def get_score_params(teams)
    {
      team_a_score: teams.first.score,
      team_b_score: teams.last.score
    }
  end

  def domain
    "#{SERVER_CONFIG['protocol']}://#{SERVER_CONFIG['domain']}:#{SERVER_CONFIG['port'] || 80}"
  end

  private

  def connect
    @client = WebSocket.new File.join(domain, 'websocket')
  end

  def log_error(e)
    puts "[SERVER ERROR] #{e.message}"
    puts e.backtrace
  end
end