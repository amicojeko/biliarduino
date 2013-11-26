require 'yaml'

SERVER_CONFIG = YAML.load_file File.expand_path('../../config/server.yml', __FILE__)

module Server
  extend self

  def start_match(teams)
    payload = get_player_params(teams)
    Httparty.post server_domain.join('matches'), payload
    # posts to http://localhost:3000/matches.json
    # p1, p2, p3, p4 data
    # team1, team2 data
    # match is created, id is returned and must be stored.
    # Now there is no need to handle more than 1 match at the same time, so
    # we could go with a singular resource instead of the plural resources.
    # Anyway this is not crystal clear, and starting with the capability to
    # handle more matches at the same time doesn't add much overhead.
  end

  def close_match(teams)
    payload = get_player_params(teams)
    Httparty.put server_domain.join('matches/close'), payload
    # puts to http://localhost:3000/match/:id.json
    # team1, team2 data
    # match is marked finished on the server
  end

  def update_match(teams)
    payload = get_player_params(teams)
    Httparty.put server_domain.join('matches/close'), payload
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

  def domain
    "#{SERVER_CONFIG['protocol']}://#{SERVER_CONFIG['domain']}:#{SERVER_CONFIG['port'] || 80}"
  end
end