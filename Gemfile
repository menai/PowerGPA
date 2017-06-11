source "https://rubygems.org"

ruby '2.3.4'

# Metrics / monitoring
gem 'librato-rack'
gem 'rollbar'

# Web stack
gem 'activesupport'
gem 'nokogiri', '1.7.1'
gem 'puma'
gem "rack", "~> 2"
gem "sinatra", github: 'sinatra/sinatra'

# PS API
gem "savon", "~> 2.0"
gem "httpclient", "~> 2.4.0"

# Util
gem 'fast_blank'

group :development do
  gem "foreman"
  gem "pry"
  gem "rake"
end

group :development, :test do
  gem 'rspec'
end

group :production do
  gem 'remote_syslog_logger'
end

group :test do
  gem 'rack-test'
end
