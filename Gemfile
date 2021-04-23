source 'https://rubygems.org'

ruby '2.5.7'

gem 'dotenv-rails', require: 'dotenv/rails-now', groups: [:development, :test]

gem 'rails', '6.0.3.6'

gem 'pg', '~> 0.21'
gem 'oj', '~> 2.18.5'
gem 'rollbar', '~> 2.15.6'

group :development do
#  gem 'guard-livereload', '~> 2.4', require: false # security
#  gem 'rerun' # security
  gem 'annotate'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'
end

gem 'sinatra'
gem 'redis'
gem "bower-rails", "~> 0.9.2"

gem 'simple_form' # for security, ">= 5.0.0"
gem 'faraday'
gem 'sidekiq'
# gem 'sidekiq-unique-jobs', '~> 4.0.18'
gem 'puma'

# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry'
  gem 'pry-byebug'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.7.2'
end

group :test do
  gem 'rails-controller-testing'
end
