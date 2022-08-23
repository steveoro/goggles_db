# frozen_string_literal: true

module GogglesDb
  #
  # = UserWorkshop model
  #
  #   - version:  7-0.4.01
  #   - author:   Steve A.
  #
  # Allows to manage user-driven or team-driven swimming workshops
  # or special training sessions where chronometric results should be recorded
  # and accounted for.
  #
  # These are different from the "official" Meetings because they do not concur in
  # any Federation Championship or ranking. (They can be used for internal Team Championships,
  # though.)
  #
  # Workshop allows also different swimmers to compete in the same
  # event in different pools, giving us sorts of "remote Meetings" that
  # can be used to compare the same event results across distances.
  #
  class UserWorkshop < AbstractMeeting
    self.table_name = 'user_workshops'

    belongs_to :user # "Creator" of this workshop
    belongs_to :team # Team arraging this Workshop, if none
    validates_associated :user
    validates_associated :team
    alias home_team team # (new, old)

    default_scope { includes(:user, :team) }

    has_one :season_type, through: :season
    has_one :federation_type, through: :season

    belongs_to :swimming_pool, optional: true # Default pool of the venue (can be null, can be set directly on results)

    # First-level children: (they "belongs_to" meeting)
    has_many :user_results, -> { order(:event_date) }, dependent: :delete_all
    has_many :pool_types,   through: :user_results
    has_many :event_types,  through: :user_results
    has_many :swimmers,     through: :user_results

    validates :header_date, presence: true

    # (For sorting scopes: see AbstractMeeting)

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Fulltext search with additional domain inclusion by using standard "LIKE"s
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      includes([:edition_type])
        .where('MATCH(user_workshops.description, user_workshops.code) AGAINST(?)', name)
        .or(includes([:edition_type]).where('user_workshops.description like ?', like_query))
        .or(includes([:edition_type]).where('user_workshops.code like ?', like_query))
        .by_date(:desc)
    }

    scope :for_user, ->(user) { joins(:user).where(user_id: user.id) }
    scope :for_team, ->(team) { joins(:team).where(team_id: team.id) }
    scope :for_swimmer, lambda { |swimmer|
      ids = includes(:swimmers).joins(:swimmers).where('swimmers.id': swimmer.id).distinct.pluck(:id)
      ids.uniq!
      where(id: ids).by_date(:desc)
    }

    # Returns +true+ if the specified +workshop+ has registered any kind of attendance or presence for the specified +swimmer+;
    # +false+ otherwise.
    def self.swimmer_presence?(workshop, swimmer)
      GogglesDb::UserResult.includes(:user_workshop).joins(:user_workshop).exists?('user_workshops.id': workshop.id, swimmer_id: swimmer.id)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes main associations into the typical to_json output.
    def to_json(options = nil)
      minimal_attributes.merge(
        'user' => user.minimal_attributes,
        'home_team' => team.minimal_attributes,
        'swimming_pool' => swimming_pool&.minimal_attributes
      ).to_json(options)
    end
  end
end
