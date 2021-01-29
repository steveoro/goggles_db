# frozen_string_literal: true

# == SimpleCov: Test coverage report formatter setup ==
#
# [Steve A., 20201030]
# SimpleCov is used as report formatter by the following services:
# (the result is a static HTML report inside '/coverage')
#
# - CoverAlls.io:
#   Code quality report works best when prepared under a CI service with a
#   structured build. Uses the COVERALLS_REPO_TOKEN variable.
#   By choice, this specific coverage report is currently set to be updated only
#   after a successful Semaphore 2.0 build.
#
# - CodeClimate.com...:
#   This report can be updated both from the Semaphore builds as well as from
#   a local test suite run, but needs the ENV variable CODECLIMATE_REPO_TOKEN
#   to be set. (Run './send_coverage.sh' for this - see below)
#
# - CodeCov.io........:
#   As above, but it needs CODECOV_TOKEN instead before the test suite run.
#
# The last ENV variable set will overwrite the SimpleCov formatter used.
#
# Only CodeClimate.com allows to re-processing of the /coverage folder to extract
# the report data without re-running the test suite. For the other 2 services at
# the moment that is not so easily done.
#
# Thus, to avoid running the tests 2 times in order to have different code coverage
# reports for comparison, we'll choose to delegate Coveralls.io to the CI setup and
# just update CodeCov.io only locally, while CodeClimate can be updated in both ways.
#
# To update the code coverage from localhost, run './send_coverage.sh'
# (ask Steve if you haven't got a copy - the Bash file includes the tokens).
#
# The script will re-run the whole test suite just 1 time and send the overall resulting
# report to both CodeCov.io & CodeClimate.com, using the latest commit as version ID
# of the code coverage report.
#
require 'simplecov'
SimpleCov.start 'rails'
puts 'SimpleCov required and started.'

# Let's give Coveralls priority if both ENV variables are set:
if ENV['COVERALLS_REPO_TOKEN'].to_s.present?
  require 'coveralls'
  Coveralls.wear!
  puts 'Coveralls.io selected for reporting output.'

elsif ENV['CODECOV_TOKEN'].to_s.present?
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  puts 'CodeCov.io selected for reporting output.'
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'devise' # NOTE: require 'devise' after require 'rspec/rails' (this allows to use devise test helpers)

# Add factories from core engine into the dummy app:
require 'factory_bot_rails'
FactoryBot.definition_file_paths << "#{GogglesDb::Engine.root}/spec/factories"
FactoryBot.reload

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Add helpers to get Devise working with RSpec
  config.include(Devise::Test::ControllerHelpers, type: :controller)
  config.include(Devise::Test::ControllerHelpers, type: :view)
  config.include(Devise::TestHelpers, type: :features)

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace('gem name')
end
