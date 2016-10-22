module PowerGPA
  class GPACalculator
    def initialize(grades)
      @grades = grades
    end

    def to_h
      return 0 unless @grades.size > 0

      # first convert based on unweighter GPA scale
      @grades.each do |course, grade|
        @grades[course] =
          if grade >= 92.5
            4.0
          elsif grade >= 89.5 && grade < 92.5
            3 + Rational(2, 3).to_f
          elsif grade >= 86.5 && grade < 89.5
            3 + Rational(1, 3).to_f
          elsif grade >= 82.5 && grade < 86.5
            3.0
          elsif grade >= 79.5 && grade < 82.5
            2 + Rational(2, 3).to_f
          elsif grade >= 76.5 && grade < 79.5
            2 + Rational(1, 3).to_f
          elsif grade >= 72.5 && grade < 76.5
            2
          elsif grade >= 69.5 && grade < 72.5
            1 + Rational(2, 3).to_f
          elsif grade >= 66.5 && grade < 69.5
            1 + Rational(1, 3).to_f
          elsif grade >= 64.5 && grade < 66.5
            1
          else
            0
          end
      end

      # next convert to weighted scale
      @grades.each do |course, grade|
        @grades[course] =
          if course.start_with?('AP ')
            grade + Rational(2, 3).to_f
          elsif course.include?('Acc')
            grade + Rational(1, 3).to_f
          else
            # no-op
            grade
          end
      end

      @grades.reject! { |k, v| v.nil? }

      # add up the weighted numbers, and divide by the number of classes being taken
      grades_sum = @grades.values.inject(0) { |sum, x| sum + x }

      # return the sum divided by the number of classes!
      (grades_sum / @grades.keys.size)
    end
  end
end
