require 'sinatra/base'

require_relative 'lib/grade_fetcher'
require_relative 'lib/gpa_calculator'

module PowerGPA
  class Application < ::Sinatra::Base
    enable :sessions
    set :show_exceptions, :after_handler

    get '/' do
      @current_error = request.session['powergpa.error']
      request.session['powergpa.error'] = nil

      erb :index
    end

    post '/gpa' do
      @students = GradeFetcher.new(params).to_h
      @students.each do |name, grade_info|
        @students[name] = {}
        @students[name]['grade_info'] = grade_info
        @students[name]['GPA'] = GPACalculator.new(grade_info).to_h
      end

      erb :gpa
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
  end
end
