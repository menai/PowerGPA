require_relative 'api_client'

module PowerGPA
  class GradeFetcher
    def initialize(params)
      @params = params
    end

    def to_h
      fetch_data
    end

    private

    def fetch_data
      api = APIClient.new(@params[:ps_url], @params[:ps_username], @params[:ps_password], @params[:ps_type])
      api.connect
      api.grades
    end
  end
end
