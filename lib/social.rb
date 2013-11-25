require 'twitter'
require 'yaml'

SOCIAL_CONFIG = YAML.load_file File.expand_path('../../config/social.yml', __FILE__)

Twitter::Streaming::Client.new do |config|
  config.consumer_key       = SOCIAL_CONFIG['twitter_key']
  config.consumer_secret    = SOCIAL_CONFIG['twitter_secret']
  config.oauth_token        = SOCIAL_CONFIG['twitter_oauth_token']
  config.oauth_token_secret = SOCIAL_CONFIG['twitter_oauth_secret']
end

class Social
	def tweet(message)
		Twitter.update message
	end
end