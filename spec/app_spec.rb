require 'spec_helper'

describe PowerGPA::Application do
  include Rack::Test::Methods

  describe '/' do
    it 'returns http 200' do
      get '/'
      expect(last_response.status).to eq(200)
    end
  end

  private

  def app
    PowerGPA::Application.new
  end
end
