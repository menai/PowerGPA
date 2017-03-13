module PowerGPA
  autoload :APIClient,              'power_gpa/api_client'
  autoload :Application,            'power_gpa/application'
  autoload :DisabledAccountStudent, 'power_gpa/disabled_account_student'
  autoload :GPACalculator,          'power_gpa/gpa_calculator'
  autoload :MetricsSender,          'power_gpa/metrics_sender'
  autoload :RollbarReporter,        'power_gpa/rollbar_reporter'
  autoload :Student,                'power_gpa/student'
end
