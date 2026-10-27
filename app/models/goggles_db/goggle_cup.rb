# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::GoggleCup
  #
  # - version:  7-0.7.10
  # - author:   Steve A.
  #
  class GoggleCup < ApplicationRecord
    self.table_name = 'goggle_cups'

    belongs_to :team
    validates_associated :team

    validates :season_year, presence: true,
                            numericality: { only_integer: true, greater_than: 2000 }
    validates :description, presence: true,
                            uniqueness: { scope: %i[team_id season_year] }
    validates :name, presence: true, length: { maximum: 60 }
    validates :published, inclusion: { in: [true, false] }

    # +name+ defaults to the (possibly truncated) description when blank, so
    # cups created without an explicit name never hit the NOT NULL column.
    before_validation { self.name = description.to_s.truncate(60, omission: '') if name.blank? }

    # Cups marked as "made visible" for their affiliation:
    scope :published, -> { where(published: true) }
    scope :for_season_year, ->(year) { where(season_year: year.to_i) }
    # Cups having the given swimmer id inside their swimmers_ids CSV list:
    scope :involving_swimmer, ->(swimmer_id) { where('FIND_IN_SET(?, swimmers_ids)', swimmer_id.to_i) }

    # Returns the published cup(s) for the given team + championship year
    # affiliation (at most one row, guaranteed also at the DB level by the
    # unique published_key index).
    def self.published_for(team_id, season_year)
      published.where(team_id: team_id, season_year: season_year.to_i)
    end

    # Returns the latest published cup involving the given swimmer, optionally
    # restricted to a single championship year.
    def self.latest_published_involving(swimmer_id, season_year: nil)
      scope = published.involving_swimmer(swimmer_id)
      scope = scope.for_season_year(season_year) if season_year.present?
      scope.order(season_year: :desc, updated_at: :desc).first
    end

    # Marks this cup as the only published one for its (team_id, season_year)
    # affiliation, resetting the flag on every sibling cup in a transaction.
    def publish!
      transaction do
        # rubocop:disable-next Rails/SkipsModelValidations -- bulk reset of sibling cups; uniqueness enforced by the published_key index
        self.class.where(team_id: team_id, season_year: season_year)
            .where.not(id: id)
            .update_all(published: false)
        update!(published: true)
      end
    end

    # Clears the published flag on this cup.
    def unpublish!
      update!(published: false)
    end

    # Returns the comma-separated swimmers_ids as an array of integers.
    def swimmer_ids_array
      swimmers_ids.to_s.split(',').map(&:to_i).reject(&:zero?)
    end

    # Sets swimmers_ids from an array of integers (or strings).
    def swimmer_ids_array=(arr)
      self.swimmers_ids = Array(arr).compact_blank.map(&:to_i).join(',')
    end
  end
end
