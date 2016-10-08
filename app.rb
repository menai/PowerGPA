require 'sinatra/base'

require_relative 'lib/grade_fetcher'
require_relative 'lib/gpa_calculator'

module PowerGPA
  class Application < ::Sinatra::Base
    set :show_exceptions, :after_handler

    get '/' do
      erb :index
    end

    post '/gpa' do
      @grades = GradeFetcher.new(params).to_h
      @grades.each do |name, grade_info|
        @grades[name] = {}
        @grades[name]['grade_info'] = grade_info
        @grades[name]['GPA'] = GPACalculator.new(grade_info).to_h
      end
      puts "jon moss"
      erb :gpa
    end

    get '/about' do
      erb :about
    end

    error 404 do
      redirect '/'
    end

    error 500 do
      redirect '/'
    end

  end
end
