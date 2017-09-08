source "https://rubygems.org"

ruby '2.3.4'

# Metrics / monitoring
gem 'librato-rack'
gem 'rollbar'

# Web stack
gem 'activesupport'
gem "foreman"
gem 'nokogiri', '1.7.1'
gem 'puma'
gem "rack", "~> 2"
gem "sinatra", '2.0.0'

# PS API
gem "savon", "~> 2.0"
gem "httpclient", "~> 2.4.0"

# Util
gem 'dotenv'
gem 'fast_blank'
#gem 'macluster-deploy', git: 'https://github.com/maclover7/macluster-deploy'

group :development do
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
