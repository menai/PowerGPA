module PowerGPA
  class APIClient
    class Student
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

      def grades
        data = fetch['return']['studentDataVOs']

        if data.is_a?(Hash)
          data = [data]
        end

        return_data = {}

        data.each do |d|
          return_data[d['student']['firstName']] = final_grades(data)
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

      def final_grades(data)
        next unless data['finalGrades']

        courses = {}
        terms = []
        final_grades = {}

        data['sections'].each do |sect|
          if valid_section?(sect)
            courses[section_title(sect)] = sect['id']
          end
        end

        data['reportingTerms'].each do |term|
          # check if start date has occurred already, and that the end date has *not* occurred already
          if (Date.parse(term['startDate']) < Date.today) && (Date.parse(term['endDate']) > Date.today)
            terms << term['id']
          end
        end

        data['finalGrades'].each do |grade|
          if valid_grade?(grade, courses, terms)
            final_grades[courses.key(grade['sectionid'])] = grade['percent']
          end
        end

        final_grades
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
