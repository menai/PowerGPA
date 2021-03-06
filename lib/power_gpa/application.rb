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
    set :http_origin, ENV['HTTP_ORIGIN']

    if environment == :production
      use Rack::Session::Cookie, {
        :key => '_powergpa_1_session',
        :domain => '.powergpa.com',
        :path => '/',
        :secret =>  ENV['SESSION_SECRET']
      }

      require 'logger'
      logger = Logger.new(Dir.pwd + '/app.log')
      use Rack::CommonLogger, logger

      #require 'remote_syslog_logger'

      #logger = RemoteSyslogLogger.new(
        #ENV['PAPERTRAIL_HOST'],
        #ENV['PAPERTRAIL_PORT'],
        #{ program: 'powergpa-macluster' })
      #use Rack::CommonLogger, logger
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

    post '/api/v1/gpa' do
      unless env['HTTP_ORIGIN'].include?(self.class.http_origin)
        status 422
        return ''
      end

      params_present = ['ps_type', 'ps_url', 'ps_username', 'ps_password'].all? do |key|
        params.key?(key)
      end

      if params_present
        calculate_gpa
        JSON.dump({ students: @students })
      else
        status 422
        content_type 'application/json'

        JSON.dump({
          error: {
            name: 'missing_params',
            description: 'Some of the required parameters are missing.'
          }
        })
      end
    end

    get '/ping' do
      'ok'
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
      def calculate_gpa
        if !params[:ps_url] || (params[:ps_url] && params[:ps_url].blank?)
          params.merge!({ ps_url: 'ps2.millburn.org' })
        end

        Librato.timing 'gpa.calculate.time' do
          @students = RequestProcessor.new(params).call
        end

        Librato.increment 'gpa.calculate.count'

        if params[:ps_terms_for_data]
          Librato.increment 'gpa.calculate.mp'
        end
      end

      def calculate_gpa_and_return
        process_parameters

        if !params[:ps_url] || (params[:ps_url] && params[:ps_url].blank?)
          params.merge!({ ps_url: 'ps2.millburn.org' })
        end

        calculate_gpa
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
