$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'power_gpa'

if ENV['RACK_ENV'] == 'production'
  puts 'Loading environment variables for the production environment...'

  require 'dotenv'
  Dotenv.load
end

use PowerGPA::MetricsSender
run PowerGPA::Application
