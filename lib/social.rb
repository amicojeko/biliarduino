require 'twitter'
require 'yaml'

CONFIG = YAML.load_file File.expand_path('../../config/social.yml', __FILE__)

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

# require 'twitter'


# Twitter.configure do |config|
#   config.consumer_key       = "bf2OVTMjsZAFX59SZNJtlQ"
#   config.consumer_secret    = "2rLO0evwXbvvcxwwZtmlLVSFbPA2CgAjd6hm27daM2A"
#   config.oauth_token        = "2201562109-oymQYXUsGTkkpoNzMy0cE8KHrr6MEDQLhcPbuzc"
#   config.oauth_token_secret = "doEKc88NoJrpUcJacvhwjsBEnqUejvYpZlg3UNGlaO12g"
# end

# class Social
#   def tweet(message)
#     Twitter.update message
#   end
# end