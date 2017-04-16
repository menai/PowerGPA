require 'sinatra/base'
require 'active_support'
require 'active_support/message_encryptor'
require 'fast_blank'

require 'power_gpa/gpa_calculator'
require 'power_gpa/metrics_sender'
require 'power_gpa/request_processor'
require 'power_gpa/rollbar_reporter'

module PowerGPA
  class Application < ::Sinatra::Base
    enable :logging
    set :show_exceptions, :after_handler
    set :public_folder, File.expand_path("../../public/", File.dirname(__FILE__))
    set :views, File.expand_path("../../views/", File.dirname(__FILE__))

    if environment == :production
      use Rack::Session::Cookie, {
        :key => '_powergpa_1_session',
        :domain => '.powergpa.com',
        :path => '/',
        :secret =>  ENV['SESSION_SECRET']
      }

      require 'remote_syslog_logger'

      logger = RemoteSyslogLogger.new(
        ENV['PAPERTRAIL_HOST'],
        ENV['PAPERTRAIL_PORT'],
        { program: 'powergpa-macluster' })
      use Rack::CommonLogger, logger
    else
      use Rack::Session::Cookie, {
        :key => '_powergpa_1_session',
        :domain => 'localhost',
        :path => '/',
        :secret => 'development12345'
      }
    end

    get '/' do
      @current_error = request.session['powergpa.error']
      request.session['powergpa.error'] = nil

      if @current_error
        erb :index
      else
        if stored_credentials?
          redirect '/gpa'
        else
          erb :index
        end
      end
    end

    get '/gpa' do
      calculate_gpa_and_return
    end

    post '/gpa' do
      calculate_gpa_and_return
    end

    get '/about' do
      erb :about
    end

    get '/clear_credentials' do
      clear_credentials
      redirect '/'
    end

    error 404 do
      redirect '/'
    end

    error 500 do
      if $!.class == APIClient::InvalidCredentialsError
        request.session['powergpa.error'] = :invalid_credentials
      elsif $!.class == APIClient::InvalidURLError
        request.session['powergpa.error'] = :invalid_url
      elsif $!.class == APIClient::CorruptedDataError
        clear_credentials
      else
        RollbarReporter.call(env)
        request.session['powergpa.error'] = :unknown
      end

      redirect '/'
    end

    private
      def calculate_gpa_and_return
        process_parameters

        Librato.timing 'gpa.calculate.time' do
          @students = RequestProcessor.new(params).call
        end

        Librato.increment 'gpa.calculate.count'

        if params[:ps_terms_for_data]
          Librato.increment 'gpa.calculate.mp'
        end

        erb :gpa
      end

      def clear_credentials
        request.session['powergpa.credentials'] = nil
      end

      def encryptor
        @encryptor ||= ActiveSupport::MessageEncryptor.new(self.class.session_secret)
      end

      def process_parameters
        write_credentials if request.post?
        params.merge!(read_credentials)

        if !params[:ps_url] || (params[:ps_url] && params[:ps_url].blank?)
          params.merge!({ ps_url: 'ps2.millburn.org' })
        end
      end

      def read_credentials
        return_value = {}

        return return_value if !user_credentials

        begin
          request.session['powergpa.credentials'].each do |k, v|
            return_value[k] = encryptor.decrypt_and_verify(v)
          end
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          request.session['powergpa.credentials'] = nil
          return_value = {}
        end

        return_value
      end

      def stored_credentials?
        user_credentials && !user_credentials.empty?
      end

      def user_credentials
        request.session['powergpa.credentials']
      end

      def write_credentials
        request.session['powergpa.credentials'] ||= {}

        ['ps_type', 'ps_url', 'ps_username', 'ps_password'].each do |key|
          request.session['powergpa.credentials'][key] =
            encryptor.encrypt_and_sign(params[key])
        end
      end
  end
end
