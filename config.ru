require 'librato-rack'
use Librato::Rack

require_relative "./app.rb"
run PowerGPA::Application
