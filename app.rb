require 'sinatra/base'

module PowerGPA
  class Application < ::Sinatra::Base
    get '/' do
      erb :index
    end
  end
end
