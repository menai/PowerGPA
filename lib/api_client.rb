require 'savon'
require 'json'

module PowerGPA
  class APIClient
    attr_reader :type

    def initialize(url, username, password, type)
      @url = url
      @username = username
      @password = password
      @type = type
    end

    def connect
      soap_endpoint = @url + "/pearson-rest/services/PublicPortalService"

      client = Savon.client(
        endpoint: soap_endpoint,
        namespace: "http://publicportal.rest.powerschool.pearson.com/xsd",
        wsse_auth: ["pearson", "pearson"]
      )

      login = client.call(:login, message: { username: @username, password: @password, userType: @type } )
      session = login.body[:login_response][:return][:user_session_vo]

      @driver = Student.new(self, @url, session)
    end

    def grades
      connect unless @driver
      @driver.grades
    end

    private

    class Student
      def initialize(client, url, session)
        @client = client
        @url = url
        @session = session
      end

      def grades
        data = fetch['return']['studentDataVOs']
        courses = {}
        final_grades = {}
        if data.is_a?(Hash)
          data = [data]
        end
        data.each do |d|
          puts data.size
          d['sections'].each do |sect|
            courses[sect['schoolCourseTitle']] = sect['id']
          end

          d['finalGrades'].each do |grade|
            if !grade['percent'].nil? && courses.values.include?(grade['sectionid']) && current_term_ids(d).include?(grade['reportingTermId']) && grade['percent'] != 0
              final_grades[courses.key(grade['sectionid'])] = grade['percent']
            end
          end
        end

        final_grades
      end

      private

      def current_term_ids(d)
        @current_term_ids ||=
          begin
            terms = []

            d['reportingTerms'].each do |term|
              # check if start date has occurred already, and that the end date has *not* occurred already
              if (Date.parse(term['startDate']) < Date.today) && (Date.parse(term['endDate']) > Date.today)
                terms << term['id']
              end
            end

            terms
          end
      end

      def fetch
        student_client = Savon.client(
          endpoint: @url + "/pearson-rest/services/PublicPortalServiceJSON?response=application/json",
          namespace: "http://publicportal.rest.powerschool.pearson.com/xsd",
          digest_auth: ["pearson", "m0bApP5"]
        )

        transcript_params = {
          userSessionVO: {
            userId: @session[:user_id],
            serviceTicket: @session[:service_ticket],
            serverInfo: {
              apiVersion: @session[:server_info][:api_version]
            },
            userType: @client.type.to_s
          },
          studentIDs: @session[:student_i_ds],
          qil: {
            includes: "1"
          }
        }

        transcript = student_client.call(:get_student_data, message: transcript_params).to_xml
        JSON.parse(transcript)
      end
    end
  end
end
