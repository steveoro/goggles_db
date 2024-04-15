# frozen_string_literal: true

module GogglesDb
  #
  # = Team model
  #
  #   - version:  7-0.7.09
  #   - author:   Steve A.
  #
  class Team < ApplicationRecord
    self.table_name = 'teams'

    belongs_to :city, optional: true

    default_scope { left_outer_joins(:city) }

    has_many :badges, dependent: :delete_all
    has_many :swimmers, through: :badges # May be used with uniq
    has_many :team_affiliations, dependent: :delete_all
    has_many :seasons, through: :team_affiliations
    has_many :season_types, through: :team_affiliations

    has_many :managed_affiliations,  through: :team_affiliations
    # has_many :meeting_individual_results
    # has_many :meetings, through: :meeting_individual_results
    # has_many :meeting_relay_results
    # has_many :meeting_team_scores
    # has_many :goggle_cups
    # has_many :computed_season_ranking
    # has_many :team_passage_templates

    validates :name, presence: { length: { within: 1..60, allow_nil: false } }
    validates :editable_name, presence: { length: { within: 1..60, allow_nil: false } }

    validates :address,       length: { maximum: 100 }
    validates :phone_mobile,  length: { maximum:  40 }
    validates :phone_number,  length: { maximum:  40 }
    validates :fax_number,    length: { maximum:  40 }
    validates :e_mail,        length: { maximum: 100 }
    validates :contact_name,  length: { maximum: 100 }
    validates :home_page_url, length: { maximum: 150 }

    #-- ------------------------------------------------------------------------
    #   Sorting scopes:
    #-- ------------------------------------------------------------------------
    #++

    scope :by_name, ->(dir = :asc) { order(name: dir) }

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Fulltext search by name with additional domain inclusion by using standard "LIKE"s
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      where('MATCH(teams.name) AGAINST(?)', name)
        .or(where('MATCH(teams.editable_name) AGAINST(?)', name))
        .or(where('MATCH(teams.name_variations) AGAINST(?)', name))
        .or(where('teams.name like ?', like_query))
        .or(where('teams.editable_name like ?', like_query))
        .or(where('teams.name_variations like ?', like_query))
    }

    # TODO: CLEAR UNUSED
    # scope :with_results, -> { where('EXISTS(SELECT 1 from meeting_individual_results where not is_disqualified and team_id = teams.id)') }
    # scope :with_min_results, lambda(how_many = 20) {
    #   where(['(SELECT count(id) from meeting_individual_results where not is_disqualified and team_id = teams.id) > ?', how_many])
    # }
    #-- -----------------------------------------------------------------------
    #++

    # Instance scope helper for recent badges, given a list of years
    # def recent_badges(year_list = [Time.zone.today.year - 1, Time.zone.today.year])
    def recent_badges(year_list = [Time.zone.today.year - 1, Time.zone.today.year])
      badges.for_years(*year_list)
    end

    # Instance scope helper for recent team_affiliations, given a list of years
    # def recent_affiliations(year_list = [Time.zone.today.year - 1, Time.zone.today.year])
    def recent_affiliations(year_list = [Time.zone.today.year - 1, Time.zone.today.year])
      team_affiliations.for_years(*year_list)
    end
    #-- -----------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %w[city]
    end

    # Override: returns the list of multiple association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def multiple_associations
      %w[]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label,
        'short_label' => decorate.short_label,
        'city_name' => city&.decorate&.display_label
      )
    end

    # Override: include only some of the rows from multiple_associations in the output.
    #
    def to_hash(options = nil)
      super(options).merge(
        'team_affiliations' => recent_affiliations.map(&:minimal_attributes)
      )
    end
  end
end
