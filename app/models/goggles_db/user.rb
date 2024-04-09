# frozen_string_literal: true

module GogglesDb
  #
  # = User model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class User < ApplicationRecord
    PLACEHOLDER_ID = 3

    self.table_name = 'users'

    after_create :associate_to_swimmer!
    before_destroy :amend_fk_rows!
    after_save :validate_swimmer_association

    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable,
           :omniauthable, omniauth_providers: %i[facebook]

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

    default_scope { includes(:swimmer, :swimmer_level_type, :coach_level_type) }

    has_many :admin_grants, dependent: :destroy
    has_many :import_queues, dependent: :destroy
    has_many :issues, dependent: :destroy
    has_many :managed_affiliations, dependent: :destroy

    # [Steve A.] FKeys are active on the following 3, so any 'dependent:' option won't count
    # because the callback is yield only *after* the user row is destroyed and the FK in place
    # will force a rollback before the action is actually carried out.
    has_many :meeting_reservations, dependent: :destroy
    has_many :user_workshops, dependent: :destroy
    has_many :user_results, dependent: :destroy

    validates :email, presence: true, uniqueness: { case_sensitive: false, message: :already_exists }
    validates :name, presence: true, uniqueness: { case_sensitive: true, message: :already_exists }

    validates :description,   length: { maximum: 100 } # Same as Swimmer#complete_name
    validates :first_name,    length: { maximum: 50 }
    validates :last_name,     length: { maximum: 50 }
    validates :year_of_birth, length: { maximum: 4 }
    validates :active,        allow_nil: false, inclusion: { in: [true, false] }
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:

    # Finder for users from OAuth results. Should never raise errors, even if the user is not valid.
    #
    # == Finder strategy:
    # 1. Email
    # 2. OAuth provider & UID from last login
    #
    # == Params:
    # - auth: an OmniAuth::AuthHash instance containing the user data (mostly the info fields are required)
    #
    # == Returns:
    # Always returns the User instance found matching either the OAuth email or the OAuth +provider+ & +uid+.
    # It may or may *not* be persisted, depending on user.valid? result.
    #
    # For instance, a User may be already existing with the same name but different email;
    # in this case, the caller should check for user.persisted? and display any existing user.errors.
    #
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

        # Enforce bidirectional swimmer association when user |=> swimmer but not vice-versa:
        if result_user.swimmer && result_user.swimmer_id != result_user.swimmer.associated_user_id
          result_user.swimmer.associated_user_id = result_user.id
          result_user.swimmer.save!
        end

      else
        # Try to persist the user (may yield validation errors; caller should check resulting user always)
        result_user.save
      end
      result_user
    }
    #-- ------------------------------------------------------------------------
    #++

    # Devise override.
    # This is called by devise when checking if a resource model is active or not.
    def active_for_authentication?
      # ASSUMES: default 'active' value for a new User row is 'true'
      super && active?
    end

    # Devise override.
    # Called for an inactive resource, used to customize the response message.
    # (See I18n => 'devise.failure.account_deactivated')
    def inactive_message
      active? ? super : :account_deactivated
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[swimmer]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[admin_grants managed_affiliations]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns the list of Swimmers matching this user's name, last name & year of birth.
    # Minimum requirement: last_name must be present to have some results.
    def matching_swimmers
      return Swimmer.none if last_name.blank?

      # [Steve A.] The following convoluted condition performs better in finding
      # complex western names combinations than most existing FULLTEXT indexes on swimmers. (See specs)
      or_conditions = prepare_matching_or_condition(last_name, 'last_name')

      # Add year_of_birth only when set:
      where_conditions = if year_of_birth.to_i > 1900
                           "(swimmers.year_of_birth = #{year_of_birth}) AND (#{or_conditions.join(' OR ')})"
                         else
                           "(#{or_conditions.join(' OR ')})"
                         end

      # Add first_name only when set:
      if first_name.present?
        or_conditions = prepare_matching_or_condition(first_name, 'first_name')
        where_conditions = "#{where_conditions} AND (#{or_conditions.join(' OR ')})"
      end

      Swimmer.where(ActiveRecord::Base.sanitize_sql_for_conditions(where_conditions))
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

    # Destroys all associated rows bound by foreign keys.
    # In the case of Users, those models will be:
    # - MeetingReservation (deletable)
    # - ManagedAffiliation (must be reassigned)
    # - UserWorkshop (same as above)
    # - UserResult (same as above)
    #
    # rubocop:disable Rails/SkipsModelValidations
    def amend_fk_rows!
      logger.info("\r\n=> Deleting user #{id}: #{first_name} #{last_name} (#{name} => #{email})")
      # Delete erasable stuff:
      GogglesDb::MeetingReservation.where(user_id: id).delete_all
      GogglesDb::ManagedAffiliation.where(user_id: id).delete_all
      # Move children associations to the placeholder User ID:
      GogglesDb::UserWorkshop.where(user_id: id).update_all(user_id: PLACEHOLDER_ID)
      GogglesDb::UserResult.where(user_id: id).update_all(user_id: PLACEHOLDER_ID)
    end
    # rubocop:enable Rails/SkipsModelValidations

    # Returns an Array of SQL "LIKE" String conditions, one for each name "particle" extracted by splitting
    # the given name by spaces.
    def prepare_matching_or_condition(first_or_last_name, column_name)
      first_or_last_name.to_s.split.map do |name_token|
        ActiveRecord::Base.sanitize_sql_for_conditions(["swimmers.#{column_name} LIKE ?", "%#{name_token}%"])
      end
    end
  end
end
