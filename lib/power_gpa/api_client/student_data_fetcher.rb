module PowerGPA
  class APIClient
    class StudentDataFetcher
      class InvalidStudentError < StandardError
      end

      ACC_COURSE_WHITELIST = {
        'Science Research 1' => 'Science Research 1 Acc'
      }

      AP_COURSE_WHITELIST = {
        'Science Research 2' => 'AP Science Research 2',
        'Science Research 3' => 'AP Science Research 3'
      }

      DEFAULT_TERM_FOR_DATA = { 'Q1' => [1620, 1612, 1628] }

      def initialize(client, url, session)
        @client = client
        @url = url
        @session = session
      end

      def call
        students = []
        data = fetch['return']['studentDataVOs']

        if data.is_a?(Hash)
          data = [data]
        end

        data.each do |d|
          next unless d['finalGrades']

          name = d['student']['firstName']

          begin
            grades, terms_for_data, terms_list = final_grades(d, @client.terms_for_data)
          rescue InvalidStudentError
            next
          end

          students.push(Student.new(name, grades, terms_for_data, terms_list))
        end

        students
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
            userType: @client.type
          },
          studentIDs: @session[:student_i_ds],
          qil: {
            includes: "1"
          }
        }

        transcript = student_client.call(:get_student_data, message: transcript_params).to_xml
        JSON.parse(transcript)
      end

      def final_grades(data, terms_for_data)
        if !terms_for_data || terms_for_data.empty?
          terms_for_data = DEFAULT_TERM_FOR_DATA
        end

        # Convert all values to integers, since that's the format in which
        # PowerSchool provides the data.
        terms_for_data_ids = terms_for_data.values.flatten
        terms_for_data_ids.map!(&:to_i)

        courses = {}
        terms_list = Hash.new { |k, v| k[v] = [] }
        final_grades = {}

        data['sections'].each do |sect|
          if valid_section?(sect)
            courses[section_title(sect)] = sect['id']
          end
        end

        raise InvalidStudentError if courses.empty?

        data['reportingTerms'].each do |term|
          if term['yearid'] == data['yearId']
            terms_list[term['title']] << term['id']
          end
        end

        data['finalGrades'].each do |grade|
          if valid_grade?(grade, courses, terms_for_data_ids)
            final_grades[courses.key(grade['sectionid'])] = grade['percent']
          end
        end

        [final_grades, terms_for_data, terms_list]
      end

      def section_title(section)
        course_name = section['schoolCourseTitle']

        AP_COURSE_WHITELIST[course_name] ||
          ACC_COURSE_WHITELIST[course_name] ||
          course_name
      end

      def valid_grade?(grade, courses, terms)
        !grade['percent'].nil? &&
        courses.values.include?(grade['sectionid']) &&
        terms.include?(grade['reportingTermId']) &&
        grade['percent'] != 0
      end

      def valid_section?(section)
        course_name = section['schoolCourseTitle']

        AP_COURSE_WHITELIST[course_name] ||
          ACC_COURSE_WHITELIST[course_name] ||
          ['AP', 'Acc', 'CPA', 'CPB'].any? do |name|
            course_name.include?(name)
          end
      end
    end
  end
end
