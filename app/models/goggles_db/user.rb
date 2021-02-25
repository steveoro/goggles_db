# frozen_string_literal: true

module GogglesDb
  #
  # = User model
  #
  #   - version:  7.80
  #   - author:   Steve A.
  #
  class User < ApplicationRecord
    self.table_name = 'users'

    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable,
           :omniauthable, omniauth_providers: %i[facebook google_oauth2]

    has_settings do |s|
      s.key :prefs, defaults: {
        # Inline tutorial/help:
        hide_search_help: false,
        hide_dashboard_help: false,
        # EMail notifications (for entries, registrations & results):
        notify_my_meetings: false,
        notify_new_team_meeting: false, # (Team-manager can enforce this)
        notify_any_meeting: false
      }
    end

    belongs_to :swimmer_level_type, optional: true
    belongs_to :coach_level_type, optional: true

    has_one :swimmer, foreign_key: 'associated_user_id',
                      inverse_of: :associated_user
    has_many :managed_affiliations

    validates :name, presence: true, uniqueness: { case_sensitive: true, message: :already_exists }

    validates :description,   length: { maximum: 100 } # Same as Swimmer#complete_name
    validates :first_name,    length: { maximum: 50 }
    validates :last_name,     length: { maximum: 50 }
    validates :year_of_birth, length: { maximum: 4 }
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    scope :from_omniauth, lambda { |auth|
      where(provider: auth.provider, uid: auth.uid).first_or_initialize do |user|
        user.email = auth&.info&.email
        user.password = Devise.friendly_token[0, 20]
        user.name = auth&.info&.name
        user.first_name = auth&.info&.first_name
        user.last_name = auth&.info&.last_name
      end
    }
    #-- ------------------------------------------------------------------------
    #++
  end
end
