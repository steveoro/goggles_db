# frozen_string_literal: true

module GogglesDb
  #
  # = User model
  #
  #   - version:  7.85
  #   - author:   Steve A.
  #
  class User < ApplicationRecord
    self.table_name = 'users'

    after_create :associate_to_swimmer!
    after_save   :validate_swimmer_association

    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable,
           :omniauthable, omniauth_providers: %i[facebook google_oauth2 twitter]

    # Read Settings like this:
    #
    #   > user.settings(:prefs).hide_search_help
    #
    # Update Settings like this:
    #
    #   > user.settings(:prefs).update!(hide_search_help: true)
    #
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

    belongs_to :swimmer, optional: true

    belongs_to :swimmer_level_type, optional: true
    belongs_to :coach_level_type, optional: true
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
        result_user.save!
      end
      result_user
    }
    #-- ------------------------------------------------------------------------
    #++

    # Returns the list of Swimmers matching this user's name, last name & year of birth.
    # Minimum requirement: last_name must be present to have some results.
    def matching_swimmers
      return Swimmer.none unless last_name.present?

      # [Steve A.] The following convoluted condition performs better in finding
      # complex western names combinations than most existing FULLTEXT indexes on swimmers. (See specs)

      or_condition = []
      last_name.to_s.split.each do |name_token|
        or_condition << "swimmers.last_name like \"%#{name_token}%\""
      end

      # Add year_of_birth only when set:
      where_condition = if year_of_birth.to_i > 1900
                          "(swimmers.year_of_birth = #{year_of_birth}) AND (#{or_condition.join(' OR ')})"
                        else
                          "(#{or_condition.join(' OR ')})"
                        end

      # Add first_name only when set:
      if first_name.present?
        or_condition = []
        first_name.to_s.split.each do |name_token|
          or_condition << "swimmers.first_name like \"%#{name_token}%\""
        end
        where_condition = "#{where_condition} AND (#{or_condition.join(' OR ')})"
      end

      Swimmer.where(ActiveRecord::Base.sanitize_sql_for_conditions(where_condition))
    end
    #-- ------------------------------------------------------------------------
    #++

    # == Auto-associate or force-association to a swimmer.
    #
    # Updates both user's swimmer_id & swimmer's associated_user_id columns
    # if there's a matching swimmer that's *not* already associated to another user.
    #
    # When the update is possible (with an unassociated, esplicitally given swimmer
    # or another one matching the user is available), the User instance gets automatically
    # saved together and the chosen swimmer instance gets updated as well.
    #
    # == Params:
    # - matching_swimmer: +!nil+ => try to bind the user to the matching_swimmer;
    #                               (matching_swimmer must be "free", not already associated)
    #                     +nil+  => default matching_swimmer = user.matching_swimmers.first
    #
    # == Returns:
    # - +nil+, in case the matching swimmer search was skipped (happens when the User's last_name
    #   is not known and there's no pre-chosen matching swimmer);
    #
    # - otherwise, the matching_swimmer chosen for the association (even if the update is skipped
    #   due to the swimmer being already chosen by another user).
    #
    def associate_to_swimmer!(matching_swimmer = nil)
      # Force skipping of the association if user last name is unknown and we don't have an override:
      return nil unless valid? && (last_name.present? || matching_swimmer.present?)

      matching_swimmer ||= matching_swimmers.first
      if matching_swimmer && matching_swimmer.associated_user_id.blank?
        self.swimmer_id = matching_swimmer.id
        save! # (auto-validates swimmer association on save)

      # Always validate the existing swimmer association, if any:
      else
        validate_swimmer_association
      end

      matching_swimmer
    end
    #-- ------------------------------------------------------------------------
    #++

    private

    # == Swimmer association consistency enforcer
    # If swimmer_id is set, checks that the current user.id matches the Swimmer's associated_user_id
    # and updates the Swimmer if otherwise (when different or not set).
    def validate_swimmer_association
      swimmer&.reload
      return unless swimmer && (swimmer.associated_user_id != id)

      swimmer.associated_user_id = id
      swimmer.save!
    end
  end
end
