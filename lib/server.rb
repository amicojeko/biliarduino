require 'yaml'

SERVER_CONFIG = YAML.load_file File.expand_path('../../config/server.yml', __FILE__)

module Server
  extend self

  def start_match(teams)
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
    # puts to http://localhost:3000/match/:id.json
    # team1, team2 data
    # match is marked finished on the server
  end

  def update_match(team)
    # basically, same as end_match, but dones't mark match as finished
  end
end