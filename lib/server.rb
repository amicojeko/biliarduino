require 'yaml'
require 'httparty'

SERVER_CONFIG = YAML.load_file File.expand_path('../../config/server.yml', __FILE__)

module Server
  extend self

  def start_match(teams)
    post match_url, get_player_params(teams)
  end

  def close_match(teams)
    put match_close_url, get_score_params(teams)
    # match is marked finished on the server
  end

  def update_match(teams)
    put match_url, get_score_params(teams)
    # basically, same as end_match, but dones't mark match as finished
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
      match: {
        team_a_score: teams.first.score,
        team_b_score: teams.last.score
      }
    }
  end

  def post(url, params)
    puts "[server] POST #{url} #{params.inspect}"
    begin
      HTTParty.post url, body: params
    rescue => e
      log_error(e)
    end
  end

  def put(url, params)
    puts "[server] PUT #{url} #{params.inspect}"
    begin
      HTTParty.put url, body: params
    rescue => e
      log_error(e)
    end
  end

  def match_url
    domain.join('match').to_s
  end

  def match_close_url
    domain.join('match/close').to_s
  end

  def domain
    Pathname.new "#{SERVER_CONFIG['protocol']}://#{SERVER_CONFIG['domain']}:#{SERVER_CONFIG['port'] || 80}"
  end

  def log_error(e)
    puts "[POST ERROR] #{e.message}"
    pute e.backtrace
  end

end