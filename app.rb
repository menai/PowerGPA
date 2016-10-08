require 'sinatra/base'
require 'active_support'
require 'active_support/message_encryptor'

require_relative 'lib/grade_fetcher'
require_relative 'lib/gpa_calculator'

module PowerGPA
  class Application < ::Sinatra::Base
    enable :sessions
    set :show_exceptions, :after_handler

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

    error 404 do
      redirect '/'
    end

    error 500 do
      request.session['powergpa.error'] = true
      redirect '/'
    end

    private
      def calculate_gpa_and_return
        write_credentials if remember_me?
        params.merge!(read_credentials(true)) if stored_credentials?

        @students = GradeFetcher.new(params).to_h
        @students.each do |name, grade_info|
          @students[name] = {}
          @students[name]['grade_info'] = grade_info
          @students[name]['GPA'] = GPACalculator.new(grade_info).to_h
        end

        erb :gpa
      end

      def encryptor
        @encryptor ||= ActiveSupport::MessageEncryptor.new(self.class.session_secret)
      end

      def read_credentials(decrypt = false)
        return_value = {}

        if decrypt
          request.session['powergpa.credentials'].each do |k, v|
            return_value[k] = encryptor.decrypt_and_verify(v)
          end
        else
          return_value = request.session['powergpa.credentials']
        end

        return_value
      end

      def remember_me?
        params['ps_remember'] == 'on'
      end

      def stored_credentials?
        read_credentials && !read_credentials.empty?
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
