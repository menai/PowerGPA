require 'rollbar'
require 'rollbar/request_data_extractor'

# Initialize Rollbar configuration

Rollbar.configure do |config|
  config.disable_monkey_patch = true
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
end

# Declare protected fields which contain user senstivie information...

protected_fields = [:ps_type, :ps_username, :ps_password]
Rollbar.configuration.scrub_headers |= protected_fields
Rollbar.configuration.scrub_fields |= protected_fields

# Create the RollbarReporter used in app.rb to send error information to Rollbar...

module PowerGPA
  class RollbarReporter
    class RequestDataExtractor
      include Rollbar::RequestDataExtractor

      def from_rack(env)
        extract_request_data_from_rack(env).merge({
          :route => env["PATH_INFO"]
        })
      end
    end

    def self.call(env)
      request_data = RequestDataExtractor.new.from_rack(env)
      Rollbar.error(env['sinatra.error'], request_data)
    end

    def self.scope!(options)
      Rollbar.scope!(options)
    end
  end
end
