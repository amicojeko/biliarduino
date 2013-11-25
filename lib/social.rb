require 'twitter'
require 'yaml'

SOCIAL_CONFIG = YAML.load_file File.expand_path('../../config/social.yml', __FILE__)

Twitter.configure do |config|
  config.consumer_key       = SOCIAL_CONFIG['twitter_key']
  config.consumer_secret    = SOCIAL_CONFIG['twitter_secret']
  config.oauth_token        = SOCIAL_CONFIG['twitter_oauth_token']
  config.oauth_token_secret = SOCIAL_CONFIG['twitter_oauth_secret']
end

class Social
	def tweet(message)
    begin
		  Twitter.update message
    rescue => e
      puts "TWITTER ERROR #{e.message}"
      puts e.backtrace
    end
	end
end