require 'savon'
require 'json'

module PowerGPA
  class APIClient
    class IncorrectCredentialsError < StandardError
    end

    attr_reader :type

    def initialize(url, username, password, type)
      @url = url
      @username = username
      @password = password
      @type = type
    end

    def connect
      unless @url.start_with?('http://') || @url.start_with?('https://')
        @url = "http://#{@url}"
      end

      soap_endpoint = @url + "/pearson-rest/services/PublicPortalService"

      client = Savon.client(
        endpoint: soap_endpoint,
        namespace: "http://publicportal.rest.powerschool.pearson.com/xsd",
        wsse_auth: ["pearson", "pearson"]
      )

      login = client.call(:login, message: { username: @username, password: @password, userType: @type } )

      if bad_credentials?(login)
        raise IncorrectCredentialsError
      else
        session = login.body[:login_response][:return][:user_session_vo]
        @driver = Student.new(self, @url, session)
      end
    end

    def grades
      connect unless @driver
      @driver.grades
    end

    private

    def bad_credentials?(login)
      login.body[:login_response][:return][:message_v_os][:title] == 'Invalid Login'
    end

    class Student
      def initialize(client, url, session)
        @client = client
        @url = url
        @session = session
      end

      def grades
        data = fetch['return']['studentDataVOs']
        courses = {}
        terms = []

        if data.is_a?(Hash)
          data = [data]
        end

        return_data = {}

        data.each do |d|
          final_grades = {}

          d['sections'].each do |sect|
            if valid_section?(sect)
              courses[sect['schoolCourseTitle']] = sect['id']
            end
          end

          d['reportingTerms'].each do |term|
            # check if start date has occurred already, and that the end date has *not* occurred already
            if (Date.parse(term['startDate']) < Date.today) && (Date.parse(term['endDate']) > Date.today)
              terms << term['id']
            end
          end

          d['finalGrades'].each do |grade|
            if valid_grade?(grade, courses, terms)
              final_grades[courses.key(grade['sectionid'])] = grade['percent']
            end
          end

          return_data[d['student']['firstName']] = final_grades
        end

        return_data
      end

      private

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

      def valid_grade?(grade, courses, terms)
        !grade['percent'].nil? &&
        courses.values.include?(grade['sectionid']) &&
        terms.include?(grade['reportingTermId']) &&
        grade['percent'] != 0
      end

      def valid_section?(section)
        ['AP', 'Acc', 'CPA', 'CPB'].any? do |name|
          section['schoolCourseTitle'].include?(name)
        end
      end
    end
  end
end
