# frozen_string_literal: true

class AddPlaceholderUser < ActiveRecord::Migration[6.0]
  require 'factory_bot_rails'

  def self.up
    # Create a placeholder user for foreing key validation to
    # enable user.destroy for users that have shared data
    # (currently: workshops, results & reservations).
    FactoryBot.definition_file_paths << "#{GogglesDb::Engine.root}/spec/factories"
    FactoryBot.reload
    return if GogglesDb::User.exists?(GogglesDb::User::PLACEHOLDER_ID)

    # This internal user will take FK place for any association involving
    # user_id for any user_id that is about to be deleted, so that the actual user
    # deletion takes place and the bound user result or reservation data
    # gets reassigned to this fake placeholder.
    FactoryBot.create(
      :user,
      id: GogglesDb::User::PLACEHOLDER_ID,
      first_name: 'Placeholder',
      last_name: "Id-#{GogglesDb::User::PLACEHOLDER_ID}",
      name: "placeholder-id-#{GogglesDb::User::PLACEHOLDER_ID}",
      email: 'fasar.software@gmail.com',
      year_of_birth: 1999
    )
  end

  def self.down
    return if GogglesDb::User.exists?(3)

    GogglesDb::User.where(id: GogglesDb::User::PLACEHOLDER_ID).destroy!
  end
end
