# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'devise'
gem 'devise-i18n'
gem 'mysql2'
gem 'scenic'
gem 'scenic-mysql_adapter'

# Declare your gem's dependencies in goggles_db.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard'
  gem 'guard-brakeman'
  gem 'guard-bundler', require: false
  gem 'guard-haml_lint'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'haml_lint', require: false
  gem 'listen', '~> 3.2'
  gem 'rubocop'
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
end

group :development, :test do
  gem 'awesome_print' # color output formatter for Ruby objects
  gem 'brakeman'
  gem 'bullet' # Currently, has issues with #reset_counters
  # gem 'byebug' # Uncomment and call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'ffaker'
  gem 'letter_opener'
  gem 'prosopite' # Bullet alternative
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'rspec'
  gem 'rspec_pacman_formatter'
  gem 'rspec-rails'
end

group :test do
  gem 'rspec_junit_formatter' # required by new Semaphore test reports
  gem 'shoulda-matchers', require: false
  gem 'simplecov', '>= 0.22', require: false
end
