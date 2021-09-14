# frozen_string_literal: true

module GogglesDb
  #
  # = ImportQueue model
  #
  #   - version:  7-0.3.31
  #   - author:   Steve A.
  #
  # Stores '/import' API requests and generic import microtransactions steps.
  #
  #
  # == How it works
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
  # === Example
  #
  # - Data-import request: new MeetingProgram
  #   |
  #   +--> needed parent entities: Season (Federation), Meeting, MeetingSession, MeetingEvent (EventType)
  #       |
  #       +--> find_or_create MeetingProgram  =>  must know & set all the IDs from the above entities
  #
  # Some of these may be missing, some may be created by a later step.
  #
  # There's a top-bottom solving order due to the depth of the association hierachy tree.
  #
  # A deeper sibling (such as Lap or MeetingIndividualResult) will definitely need more solver depth that any
  # other high-level entity (such as Season or Meeting).
  #
  # Each microtransaction can be processed iteratively and repeatedly until all unsolved bindings are fixed,
  # either by solving other microtransaction requests or by manual data input.
  #
  # A step that's able to fullfill all of its bindings (by setting all its associations IDs) during the current
  # run can be set as "solved" completely, and it becomes ready for serialization.
  #
  # After the step has been serialized (typically into a new or an existing entity row, returning the row ID
  # as solution to any upper level solver classes), it becomes "done" and it can then be "digested" (erased).
  #
  #
  # == Microtransaction States
  #
  # A step/microtransaction is:
  #
  # - unprocessed    => (process_runs == 0)
  # - processed      => (process_runs > 0)
  # - solvable       => (all required bindings for the target entity can be solved)
  # - unsolvable-yet => (missing data; some bindings are left unsolved)
  # - solved         => (all required bindings have been solved, no bindings left)
  # - done           => (solved && saved) => erasable/consumable
  #
  #
  # == Bindings are solved according to their result value & depth of association
  #
  # Bindings for a Solver class can be a specific value or a nested binding with another Solver class.
  # The field values and the IDs are set depending on the entity association depth.
  #
  # For example, Solver::Swimmer defines a simple value binding for filling in the year_of_birth, but
  # yields another Solver class (Solver::LookupEntity) for its gender_type_id. So, each binding becomes
  # naturally nested in depth, with a level of nesting depending on the actual hierachy of the target
  # entity.
  #
  # Typically, when a requested value is found and the solved field is set, the solver result will
  # be used by a dedicated process job to update the ImportQueue solved data accordingly.
  #
  #
  # == JSON request/solved data format:
  #
  # Two keys are required:
  # 1. 'target_entity' => target model name, unnamespaced (without 'GogglesDb::')
  # 2. any other root key, given by the snake-case name of the target entity
  #
  # The known column data details should be listed as a nested Hash of the root key.
  #
  # Typical valid format:
  #
  #     {
  #       'target_entity' => 'EntityName',   # (i.e.: 'MeetingEvent')
  #       'entity_name' => {                 # (i.e.: 'meeting_event')
  #         'known_field1' => field_value1,
  #         'known_field2' => field_value2,
  #         # [...]
  #       }
  #     }
  #
  class ImportQueue < ApplicationRecord
    self.table_name = 'import_queues'

    belongs_to :user
    validates_associated :user

    # Optional self-association for sibling rows:
    # (cannot enforce integrity given that the foreign key is lacking)
    belongs_to :import_queue, optional: true
    has_many :import_queues, dependent: :destroy

    alias parent import_queue # (new, old)
    alias sibling_rows import_queues # (new, old)

    validates :process_runs, presence: true, numericality: true

    # Both of the following are supposed to store only JSON text data:
    validates :request_data, presence: true
    validates :solved_data, presence: true
    # === Note:
    # - 'request_data': JSON hash obtained by parsing both request.body & request.params (from any
    #                   API's '/import' or set programmatically by a specific import command object).
    # - 'solved_data': JSON hash of solved entities IDs and field values, with the same basic structure of
    #                  request_data plus the missing IDs.

    validates :done, inclusion: { in: [true, false] }

    # Filtering scopes:
    scope :deletable, -> { where(done: true) }
    scope :for_user,  ->(user) { where(user_id: user.id) }
    scope :for_uid,   ->(uid) { where(uid: uid) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns the parsed request_data Hash
    def req
      parse_data if @req.nil?
      @req
    end

    # Returns the parsed solved_data Hash
    def solved
      parse_data if @solved.nil?
      @solved
    end

    # Returns the target entity name from the original request
    def target_entity
      req['target_entity']
    end

    # Returns the root-level key of the request hash, according to the 'target_entity' value.
    def root_key
      target_entity&.tableize&.singularize
    end

    # Similarly to root_key, returns the expected first-depth parent key of the request hash
    # according to the value of 'target_entity'.
    def result_parent_key
      {
        'user_lap' => 'user_result',
        'lap' => 'meeting_individual_result',
        'meeting_relay_swimmer' => 'meeting_relay_result'
      }.fetch(root_key, nil)
    end
    #-- ------------------------------------------------------------------------
    #++

    # Returns the associated Swimmer complete name at root-key depth of the request, if any,
    # or +nil+ when not set.
    def req_swimmer_name
      req&.fetch(root_key, nil)&.fetch('swimmer', nil)&.fetch('complete_name', nil)
    end

    # Returns the associated EventType at root-key depth of the request, if any, or +nil+ when not set.
    def req_event_type
      event_type_id = req&.fetch(root_key, nil)&.fetch(result_parent_key, nil)&.fetch('event_type_id', nil)
      @req_event_type ||= GogglesDb::EventType.find_by(id: event_type_id)
    end

    # Returns a Timing instance set with any timing data stored at root-key depth of the request,
    # or zeroed out when not found.
    def req_timing
      @req_timing ||= Timing.new(
        minutes: fetch_root_int_value('minutes'),
        seconds: fetch_root_int_value('seconds'),
        hundredths: fetch_root_int_value('hundredths')
      )
    end

    # Returns the associated 'length_in_meters' at root-key depth of the request, if any,
    # or +nil+ when not set.
    def req_length_in_meters
      @req_length_in_meters ||= fetch_root_int_value('length_in_meters')
    end

    protected

    # Returns an integer value stored as a root sibling at depth 1, using +key+.
    # Defaults to 0 if not found.
    def fetch_root_int_value(key)
      req&.fetch(root_key, nil)&.fetch(key, 0).to_i
    end

    private

    # Parses the JSON data stored in this instance and sets the #req & #solved members.
    def parse_data
      @req, @solved = begin
        [
          ActiveSupport::JSON.decode(request_data),
          ActiveSupport::JSON.decode(solved_data)
        ]
      rescue ActiveSupport::JSON.parse_error
        nil
      end
    end
  end
end
