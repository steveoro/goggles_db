# frozen_string_literal: true

module GogglesDb
  #
  # = ImportQueue model
  #
  #   - version:  7.070
  #   - author:   Steve A.
  #
  # Stores '/import' API requests and generic import microtransactions steps.
  #
  #
  # == How it works:
  #
  # Each data-import request maps to a single entity, either for the creation of a new row or the update
  # of an existing one; in other words, each request maps to a single-entity transaction.
  #
  # Table-wise, each row in this table represents a single transaction "step", a.k.a. "microtransaction".
  #
  # Each microtransaction step implies knowning (and assigning) the correct values for all subentity IDs
  # that have to be associated with the requested entity record creation or update.
  #
  # If all the association IDs for the resulting row are found from what is already existing, the step
  # can be considered as "solved". Otherwise, the step can become "solvable" on later stages, either after
  # some manual intervention or after another follow-up run.
  #
  #
  # === Example:
  #
  # - Data-import request: new MeetingProgram
  #   |
  #   +--> needed parent entities: Season (Federation), Meeting, MeetingSession, MeetingEvent (EventType)
  #       |
  #       +--> find_or_create MeetingProgram  =>  must know & set all the IDs from the above entities
  #
  # Some of these may be missing, some may be created by a later step.
  #
  # There's a top-bottom solving order due to the depth of the association hierachy tree. This enforces
  # both a minimum and a maximum number of "phase runs" before solving each step, depending on which and
  # how many associated parent entities are known (solved) at run time.
  #
  # A deeper sibling (such as Lap or MeetingIndividualResult) will definitely need more phases that any
  # other high-level entity (such as Season or Meeting).
  #
  # Each microtransaction can be processed iteratively and repeatedly using multiple passes at
  # different "depths", depeding on the group of entities being solved.
  #
  # A step that's able to fullfill all its bindings (by setting all its associations IDs) during the current
  # run can be set as "solved" completely, and it becomes ready for serialization.
  #
  # After the step has been serialized, it becomes "done" and it can then be "digested" (erased).
  #
  #
  # == Microtransaction States:
  #
  # A step/microtransaction is:
  #
  # - unprocessed    => (processed_depth == 0)
  # - processed      => (processed_depth > 0)
  # - solvable       => (solvable_depth >= requested_depth)
  # - unsolvable-yet => (processed_depth >= solvable_depth < requested_depth)
  # - solved         => (processed_depth >= requested_depth = solvable_depth)
  # - done           => (solved && saved) => erasable/digestable
  #
  #
  # == Requested / Solved fields per "depth group":
  #
  # The field values (IDs) are set by the corresponding Solver class, depending on entity/depth group.
  #
  # Typically, when a requested value is found and the solved field is set, both
  # +processed_depth+ & +solvable_depth+ are updated and set with the corresponding entity (depth) level.
  #
  # If a value is not found (or "unresolved"), the solver class will update just +processed_depth+ with
  # the corresponding depth (and the step will remain "unsolvable yet" until further runs).
  #
  # Each depth pass & entity has a dedicated 'Solver' object. See SolverModule for info.
  #
  # - Depth 1: Season => sets season_id => needs: federation_id
  # - Depth 1: Team => sets team_id => needs: team name
  # - Depth 1: Swimmer
  #            => sets swimmer_id => needs: swimmer name, year_of_birth, [+team name], [+season name]
  #
  # - Depth 2: TeamAffiliation => sets team_affiliation_id => needs: team_id, season_id
  # - Depth 2: Badge => sets badge_id => needs: swimmer_id, season_id
  #
  # - Depth 3: Meeting => sets meeting_id => needs: season_id
  # - Depth 3: MeetingSession
  #            => sets meeting_session_id => needs: meeting_id
  #
  # - Depth 4: MeetingEvent
  #            => sets meeting_event_id => needs: meeting_session_id, event_type_id
  #
  # - Depth 5: MeetingProgram
  #            => sets meeting_program_id => needs: meeting_event_id
  #
  # - Depth 6: MeetingIndividualResult
  #            => sets meeting_individual_result_id => needs: meeting_program_id, swimmer_id, team_id
  # - Depth 6: MeetingRelayResult
  #            => sets meeting_relay_result_id => needs: meeting_program_id, team_id
  # - Depth 6: MeetingTeamScore
  #            => sets meeting_team_score_id => needs: meeting_program_id, team_id
  #
  # - Depth 7: MeetingRelaySwimmer
  #            => sets: meeting_relay_swimmer_id => needs: meeting_relay_result_id, swimmer_id, team_id
  # - Depth 7: Lap => sets lap_id => needs: meeting_individual_result_id, swimmer_id, team_id
  #
  #
  # == Priority depth/entity order for API calls:
  #
  # API call type, top-bottom order:
  #
  # 1. '/import/meeting'    => depth 3 & above; params: season, federation, meeting, with description, session & registration dates
  # 2. '/import/event'      => depth 4 & above; params: meeting, date, event_type
  # 3. '/import/relay'      => depth 6 & above; params: meeting, date, team, event_type, +swimmer(s) + result(s)
  # 4. '/import/individual' => depth 6 & above; params: meeting, date, swimmer, event_type both rel. & ind., +lap(s)
  # 5. '/import/lap'        => depth 7 & above; params: meeting, date, swimmer, event_type both rel. & ind., distance (+from_start or not), timing
  # 6. '/import/scores'     => depth 7 & above; params: meeting, date, team
  #
  # Some API calls may imply more than one microtransaction.
  #
  # Should the parameters of an API call imply more than one step, it's responsibility of the API service
  # to yield all the required microtransactions row needed.
  #
  class ImportQueue < ApplicationRecord
    self.table_name = 'import_queues'

    belongs_to :user
    validates_associated :user

    validates :processed_depth, presence: true, numericality: true
    validates :requested_depth, presence: true, numericality: true
    validates :solvable_depth, presence: true, numericality: true

    # Both of the following are supposed to store only JSON data:
    validates :request_data, presence: true
    validates :solved_data, presence: true
    # === Note:
    # - 'request_data' is deduced after parsing both request.body & request.params from
    #   API's '/import' or set programmatically by a specific import command object.
    # - 'solved_data' is a JSON hash of entities IDs which have been found existing
    #   or already created by previous steps.

    validates :done, inclusion: { in: [true, false] }

    # Sorting scopes:
    # TODO

    # Filtering scopes:
    scope :for_processed_depth,  ->(depth = 0) { where(processed_depth: depth) }
    scope :for_requested_depth,  ->(depth = 0) { where(requested_depth: depth) }
    scope :for_solvable_depth,   ->(depth = 0) { where(solvable_depth: depth) }
    #-- ------------------------------------------------------------------------
    #++
  end
end
