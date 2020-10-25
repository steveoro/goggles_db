# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in goggles_db.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman'

  gem 'guard'
  gem 'guard-brakeman'
  gem 'guard-bundler', require: false
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-spring'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-commands-rubocop'
  gem 'spring-watcher-listen'
end

group :development, :test do
  gem 'bullet'
  gem 'ffaker'
  gem 'letter_opener'
  gem 'pry'
  gem 'rspec'
  gem 'rspec-rails'

  gem 'rubocop', require: false # For style checking
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
end
