# frozen_string_literal: true

module GogglesDb
  #
  # = User model
  #
  #   - version:  7.82
  #   - author:   Steve A.
  #
  class User < ApplicationRecord
    self.table_name = 'users'

    after_initialize :associate_to_swimmer!

    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable,
           :omniauthable, omniauth_providers: %i[facebook google_oauth2 twitter]

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

    # Finder for users from OAuth results.
    #
    # == Params:
    # - auth: an OmniAuth::AuthHash instance containing the user data (mostly the info fields are required)
    #
    # == Returns:
    # Returns the User matching either the OAuth email or the OAuth +provider+ & +uid+.
    # If an existing user matching the email is found, the +provider+ & +uid+ are updated.
    # If no matching users are found, returns a new pre-confirmed instance using the auth data.
    #
    scope :from_omniauth, lambda { |auth|
      return nil unless auth.is_a?(OmniAuth::AuthHash) && auth.valid?

      result_user = find_by(email: auth.info.email) ||
                    where(provider: auth.provider, uid: auth.uid).first_or_initialize do |user|
                      user.email = auth.info.email
                      user.password = Devise.friendly_token[0, 20]
                      user.name = auth.info.name
                      user.first_name = auth.info.first_name
                      user.last_name = auth.info.last_name
                      user.confirmed_at = Time.zone.now
                      user.avatar_url = auth.info.image
                    end
      # Always skip the confirmation emails since this new user comes from a trusted
      # OAuth source that already confirms them:
      result_user.skip_confirmation_notification!
      if result_user.persisted?
        result_user.update!(
          provider: auth.provider,
          uid: auth.uid,
          avatar_url: auth.info.image,
          confirmed_at: Time.zone.now
        )
        result_user.reload
      else
        result_user.associate_to_swimmer!
        result_user.save!
      end
      result_user
    }
    #-- ------------------------------------------------------------------------
    #++

    # Returns the list of Swimmers matching this user's name, last name & year of birth.
    def matching_swimmers
      # [Steve A.] The following convoluted condition performs better in finding
      # complex western names combinations than most existing FULLTEXT indexes on swimmers. (See specs)
      or_condition = []
      last_name.to_s.split.each do |name_token|
        or_condition << "swimmers.last_name like \"%#{name_token}%\""
      end
      # Add year of birth only when set:
      where_condition = if year_of_birth.to_i > 1900
                          "(swimmers.year_of_birth = #{year_of_birth}) AND (#{or_condition.join(' OR ')})"
                        else
                          "(#{or_condition.join(' OR ')})"
                        end

      or_condition = []
      first_name.to_s.split.each do |name_token|
        or_condition << "swimmers.first_name like \"%#{name_token}%\""
      end
      where_condition = "#{where_condition} AND (#{or_condition.join(' OR ')})"

      Swimmer.where(ActiveRecord::Base.sanitize_sql_for_conditions(where_condition))
    end

    # == Auto-associate to swimmer.
    # Changes the swimmer_id column if there's a matching swimmer that's
    # *not* already associated to another user.
    # The record does *not* get persisted (it still needs a manual save).
    #
    # Always returns the first swimmer found (& chosen), even when the association is not possible.
    #
    def associate_to_swimmer!
      return nil unless last_name.present? && first_name.present?

      matching_swimmer = matching_swimmers.first
      self.swimmer_id = matching_swimmer.id if matching_swimmer && matching_swimmer.associated_user_id.blank?
      matching_swimmer
    end
  end
end
