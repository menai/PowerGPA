require 'savon'
require 'json'
require 'uri'
require 'power_gpa/rollbar_reporter'
require 'power_gpa/api_client/student_data_fetcher'

module PowerGPA
  class APIClient
    class CorruptedDataError < StandardError
    end

    class InvalidCredentialsError < StandardError
    end

    class InvalidURLError < StandardError
    end

    attr_reader :terms_for_data, :type

    def initialize(url, username, password, type, terms_for_data)
      @url = url
      @username = username
      @password = password
      @type = type
      @terms_for_data = terms_for_data
    end

    def connect
      unless @url.start_with?('http://') || @url.start_with?('https://')
        @url = "http://#{@url}"
      end

      raise InvalidURLError unless valid_url?(@url)

      soap_endpoint = @url + "/pearson-rest/services/PublicPortalService"

      RollbarReporter.scope!({ soap_endpoint: soap_endpoint })

      client = Savon.client(
        endpoint: soap_endpoint,
        namespace: "http://publicportal.rest.powerschool.pearson.com/xsd",
        wsse_auth: ["pearson", "pearson"]
      )

      begin
        login = client.call(:login, message: { username: @username, password: @password, userType: @type } )
      rescue Savon::SOAPFault
        raise CorruptedDataError
      end

      if bad_credentials?(login)
        raise InvalidCredentialsError
      else
        session = login.body[:login_response][:return][:user_session_vo]
        @driver = StudentDataFetcher.new(self, @url, session)
      end
    end

    def students
      connect unless @driver
      @driver.call
    end

    private

    def bad_credentials?(login)
      login.body[:login_response][:return] &&
        login.body[:login_response][:return][:message_v_os] &&
        login.body[:login_response][:return][:message_v_os][:title] == 'Invalid Login'
    end

    def valid_url?(url)
      url = URI.parse(url).host

      begin
        Socket.gethostbyname(url)
        true
      rescue SocketError
        false
      end
    end
  end
end
