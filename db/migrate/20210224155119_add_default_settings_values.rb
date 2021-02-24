# frozen_string_literal: true

class AddDefaultSettingsValues < ActiveRecord::Migration[6.0]
  def self.up
    app_base_row = GogglesDb::AppParameter.versioning_row
    app_base_row.settings(:framework_urls).api = '0.0.0.0:8088'
    app_base_row.settings(:framework_urls).main = '0.0.0.0:8080'
    app_base_row.settings(:framework_urls).admin = '0.0.0.0:8098'
    app_base_row.settings(:framework_urls).chrono = '0.0.0.0:8090'

    app_base_row.settings(:framework_emails).contact = 'fasar.software@email.it'
    app_base_row.settings(:framework_emails).admin = 'steve.alloro@gmail.com'
    app_base_row.settings(:framework_emails).admin2 = 'leegaweb@gmail.com'
    app_base_row.settings(:framework_emails).devops = 'steve.alloro@gmail.com'

    app_base_row.settings(:social_urls).facebook = 'https://www.facebook.com/MasterGoggles'
    app_base_row.settings(:social_urls).linkedin = 'https://www.linkedin.com/in/fasar/'
    app_base_row.settings(:social_urls).twitter = 'https://twitter.com/master_goggles'
    app_base_row.save!
  end

  def self.down
    app_base_row = GogglesDb::AppParameter.versioning_row
    app_base_row.settings(:framework_urls).api = nil
    app_base_row.settings(:framework_urls).main = nil
    app_base_row.settings(:framework_urls).admin = nil
    app_base_row.settings(:framework_urls).chrono = nil
    app_base_row.settings(:framework_emails).contact = nil
    app_base_row.settings(:framework_emails).admin = nil
    app_base_row.settings(:framework_emails).devops = nil
    app_base_row.settings(:social_urls).facebook = nil
    app_base_row.settings(:social_urls).linkedin = nil
    app_base_row.settings(:social_urls).twitter = nil
    app_base_row.save!
  end
end
