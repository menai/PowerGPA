require 'sinatra/base'

require_relative 'lib/grade_fetcher'
require_relative 'lib/gpa_calculator'

module PowerGPA
  class Application < ::Sinatra::Base
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

      erb :gpa
    end
  end
end
