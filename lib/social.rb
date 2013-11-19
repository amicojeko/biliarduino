require 'twitter'
require 'yaml'

CONFIG = YAML.load_file File.expand_path('../../config.yml', __FILE__)

Twitter.configure do |config|
  config.consumer_key       = CONFIG['twitter_key']
  config.consumer_secret    = CONFIG['twitter_secret']
  config.oauth_token        = CONFIG['twitter_oauth_token']
  config.oauth_token_secret = CONFIG['twitter_oauth_secret']
end

class Social
	def tweet(message)
		Twitter.update message
	end
end