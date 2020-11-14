# frozen_string_literal: true

require 'goggles_db'
require 'ffaker'
require 'factory_bot_rails'

namespace :db do
  desc 'Anonymizes all tables in current environment DB known to store possible sensitive data'
  task anonimize_data: :environment do
    puts "\r\n*** Anonimize data ***"
    # Prevent messing around with production data:
    abort('The Rails environment is running in production mode!') if Rails.env.production?
    puts 'Importing factories...'
    FactoryBot.definition_file_paths = ["#{GogglesDb::Engine.root}/spec/factories"]
    FactoryBot.reload

    puts "\r\n--> Processing Users (1x'.' => 5x; tot. #{GogglesDb::User.count}; new default password: '#{FactoryBot.build(:user).password}')"
    # Keep the first 2 users (the original developers) intact and retrieve the rest in batches:
    GogglesDb::User.where('id > 2').find_each.with_index do |user, index|
      fake_row = FactoryBot.build(:user)
      user.update_columns(
        fake_row.attributes.compact.reject { |attr| attr == 'lock_version' }
      )
      $stdout.write("\033[1;33;32m.\033[0m") if (index % 5).zero?
    end
    puts "\r\n"

    puts "\r\n--> Processing Swimmers (1x'.' => 10x; tot. #{GogglesDb::Swimmer.count})"
    # Skip our associated swimmers (because we don't have anything to hide :-) ):
    GogglesDb::Swimmer.where('(id != 23) AND (id != 142)')
                      .find_each(batch_size: 100).with_index do |swimmer, index|
      fake_row = FactoryBot.build(:swimmer)
      swimmer.update_columns(
        fake_row.attributes.compact.reject { |attr| attr == 'lock_version' }
      )
      $stdout.write("\033[1;33;32m.\033[0m") if (index % 10).zero?
    end
    puts "\r\n"

    puts "\r\n--> Processing Teams (1x'.' => 5x; tot. tot. #{GogglesDb::Team.count})"
    GogglesDb::Team.find_each.with_index do |team, index|
      fake_row = FactoryBot.build(:team)
      team.update_columns(
        fake_row.attributes.compact.reject { |attr| attr == 'lock_version' }
      )
      $stdout.write("\033[1;33;32m.\033[0m") if (index % 5).zero?
    end
    puts "\r\n"

    puts "\r\nDone."
  end
end
