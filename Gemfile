source "https://rubygems.org"

# Metrics / monitoring
gem 'librato-rack'
gem 'rollbar'

# Web stack
gem 'activesupport'
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

group :test do
  gem 'rack-test'
end
