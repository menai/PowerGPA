module PowerGPA
  class Student
    attr_reader :name, :grades, :gpa

    def initialize(name, grades)
      @name = name
      @grades = grades
      @gpa = GPACalculator.new(@grades).to_h
    end
  end
end
