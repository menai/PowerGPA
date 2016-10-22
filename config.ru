require_relative "./lib/application.rb"

use PowerGPA::MetricsSender
run PowerGPA::Application
