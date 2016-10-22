$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'power_gpa'

use PowerGPA::MetricsSender
run PowerGPA::Application
