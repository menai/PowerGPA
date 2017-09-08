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
          name = d['student']['firstName']

          if d['schools']['schoolDisabled']
            students.push(DisabledAccountStudent.new(name, {}, {}, {}))
            next
          end

          next unless d['finalGrades']

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

      def calculate_current_term(data)
        terms = Hash.new { |k, v| k[v] = [] }

        data['reportingTerms'].each do |term|
          # Current reporting term can only be a quarter. If the title of the
          # term doesn't contain an uppercase Q, then we'll jump to the next term.
          next unless term['title'].include?('Q')

          # Check if start date has occurred already, and that the end date has *not* occurred already
          if (Date.parse(term['startDate']) <= Date.today) && (Date.parse(term['endDate']) >= Date.today)
            terms[term['title']] << term['id']
          end
        end

        terms
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
          terms_for_data = calculate_current_term(data)
        end

        # Convert all values to integers, since that's the format in which
        # PowerSchool provides the data.
        terms_for_data_ids = terms_for_data.values.flatten
        terms_for_data_ids.map!(&:to_i)

        courses = {}
        terms_list = Hash.new { |k, v| k[v] = [] }
        final_grades = {}

        data['sections'].each do |sect|
          section_title = format_section_title(sect['schoolCourseTitle'])

          if valid_section?(section_title)
            courses[section_title] = sect['id']
          end
        end

        raise InvalidStudentError if courses.empty?

        data['reportingTerms'].each do |term|
          if term['yearid'] == data['yearId']
            terms_list[term['title']] << term['id']
          end
        end

        if !data['finalGrades'].is_a?(Array)
          data['finalGrades'] = [data['finalGrades']]
        end

        data['finalGrades'].each do |grade|
          if valid_grade?(grade, courses, terms_for_data_ids)
            final_grades[courses.key(grade['sectionid'])] = grade['percent']
          end
        end

        [final_grades, terms_for_data, terms_list]
      end

      def format_section_title(course_name)
        AP_COURSE_WHITELIST[course_name] ||
          ACC_COURSE_WHITELIST[course_name] ||
          course_name
      end

      def valid_grade?(grade, courses, terms)
        !grade['percent'].nil? &&
        courses.values.include?(grade['sectionid']) &&
        terms.include?(grade['reportingTermId']) &&
        grade['percent'] != 0
      rescue => e
        $stdout.puts "BADBAD: #{grade}"
        raise e
      end

      def valid_section?(course_name)
        AP_COURSE_WHITELIST[course_name] ||
          ACC_COURSE_WHITELIST[course_name] ||
          ['AP', 'Acc', 'Honors', 'CPA', 'CPB'].any? do |name|
            course_name.include?(name)
          end
      end
    end
  end
end
