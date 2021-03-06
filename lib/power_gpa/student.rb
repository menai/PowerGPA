module PowerGPA
  class Student
    attr_reader :name, :grades, :gpa, :terms_for_data, :terms_list

    def initialize(name, grades, terms_for_data, terms_list)
      @name = name
      @grades = grades
      @gpa = GPACalculator.new(@grades).to_h
      @terms_for_data = terms_for_data
      @terms_list = terms_list
    end

    def disabled?
      false
    end

    def to_json(_state)
      JSON.dump({
        gpa: @gpa,
        grades: @grades,
        name: @name,
        terms_for_data: @terms_for_data,
        terms_list: @terms_list
      })
    end
  end
end
