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
        :key => 'rack.session',
        :domain => 'powergpa.com',
        :path => '/',
        :secret =>  ENV['SESSION_SECRET']
      }
    else
      use Rack::Session::Cookie, {
        :key => 'rack.session',
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
      request.session['powergpa.credentials'] = {}
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

        erb :gpa
      end

      def encryptor
        @encryptor ||= ActiveSupport::MessageEncryptor.new(self.class.session_secret)
      end

      def process_parameters
        write_credentials if request.post?
        params.merge!(read_credentials) if stored_credentials?
        params.merge!({ ps_url: 'ps2.millburn.org' }) if params[:ps_url].blank?
      end

      def read_credentials
        return_value = {}

        request.session['powergpa.credentials'].each do |k, v|
          return_value[k] = encryptor.decrypt_and_verify(v)
        end

        return_value
      end

      def remember_me_session_key
        request.session['powergpa.remember']
      end

      def stored_credentials?
        remember_me_session_key && remember_me_session_key == 'true'
      end

      def write_credentials
        request.session['powergpa.credentials'] ||= {}

        ['ps_type', 'ps_url', 'ps_username', 'ps_password'].each do |key|
          request.session['powergpa.credentials'][key] =
            encryptor.encrypt_and_sign(params[key])
        end

        if params['ps_remember'] == 'on'
          request.session['powergpa.remember'] = 'true'
        end
      end
  end
end
