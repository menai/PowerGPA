module PowerGPA
  class DisabledAccountStudent < Student
    def disabled?
      true
    end
  end
end
