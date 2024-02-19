# frozen_string_literal: true

module GogglesDb
  #
  # = TeamLapTemplate model
  #
  #   - version:  7-0.6.30
  #   - author:   Steve A.
  #
  class TeamLapTemplate < ApplicationRecord
    self.table_name = 'team_lap_templates'

    belongs_to :team
    belongs_to :pool_type
    belongs_to :event_type

    validates_associated :team
    validates_associated :pool_type
    validates_associated :event_type

    has_one :stroke_type, through: :event_type

    default_scope { includes(:team, :pool_type, :event_type, :stroke_type) }

    # Sorting scopes:
    scope :by_length, -> { order(:length_in_meters) }

    # Filtering scopes:
    scope :for_team,       ->(team)       { where(team_id: team.id) }
    scope :for_pool_type,  ->(pool_type)  { where(pool_type_id: pool_type.id) }
    scope :for_event_type, ->(event_type) { where(event_type_id: event_type.id) }

    # Retrieves the list of TeamLapTemplates given the parameters:
    scope :templates_for, ->(team, pool_type, event_type) { where(team_id: team.id, pool_type_id: pool_type.id, event_type_id: event_type.id).by_length }
    #-- ------------------------------------------------------------------------
    #++

    # Returns an array of default lap lengths (in meters) given the total length and the pool length.
    #
    # This array of default lengths can be used to fill & prepare any new Team lap templates set
    # (which will be likely edited by the Team manager according to personal preferences).
    def self.default_lap_lengths_for(total_length_in_meters, pool_length = 50)
      (pool_length..total_length_in_meters).step(pool_length).to_a.delete_if do |len|
        ((total_length_in_meters > 100) && (len % 50 != 0)) || (len % pool_length != 0)
      end
    end
  end
end
