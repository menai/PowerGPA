module PowerGPA
  class RequestProcessor
    def initialize(params)
      @params = params
    end

    def call
      if @params[:ps_username] == 'fakestudent123'
        [Student.new(
          'John Smith', {
            "AP European History" => 90,
            "US History I Acc" => 90,
            "Business Economics Acc" => 94,
            "Algebra II Acc" => 88,
            "Biology Acc" => 91,
            "American Literature Acc" => 86,
            "French 4 Acc" => 87
          },
          { "Q3" => [1632, 1624, 1614] },
          { "Q3" => [1632, 1624, 1614] }
        )]
      else
        api = APIClient.new(
          @params[:ps_url].strip.downcase,
          @params[:ps_username],
          @params[:ps_password],
          @params[:ps_type].to_s,
          @params[:ps_terms_for_data]
        )

        api.connect
        api.students
      end
    end
  end
end
