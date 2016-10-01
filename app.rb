require 'sinatra/base'

require_relative 'lib/grade_fetcher'

module PowerGPA
  class Application < ::Sinatra::Base
    get '/' do
      erb :index
    end

    get '/gpa' do
      content_type :json
      JSON.dump GradeFetcher.new(params).to_h
    end
  end
end
