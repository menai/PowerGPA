require 'power_gpa/api_client'

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
      if @params[:ps_username] == 'fakestudent123'
        FakeStudentGradeFetcher.grades
      else
        api = APIClient.new(@params[:ps_url].strip.downcase, @params[:ps_username], @params[:ps_password], @params[:ps_type].to_s)
        api.connect
        api.grades
      end
    end

    class FakeStudentGradeFetcher
      def self.grades
        {
          "John Smith" => {
            "AP European History" => 90,
            "US History I Acc" => 90,
            "Business Economics Acc" => 94,
            "Algebra II Acc" => 88,
            "Biology Acc" => 91,
            "American Literature Acc" => 86,
            "French 4 Acc" => 87
          }
        }
      end
    end
  end
end
