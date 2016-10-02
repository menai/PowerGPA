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
      @gpa = GPACalculator.new(@grades).to_h
      erb :gpa
      #content_type :json
      #JSON.dump({
      #  grades: grades,
      #  gpa: gpa
      #})
    end
  end
end
