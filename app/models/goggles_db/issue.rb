# frozen_string_literal: true

module GogglesDb
  #
  # = Issue model
  #
  #   - version:  7-0.5.13
  #   - author:   Steve A.
  #
  class Issue < ApplicationRecord
    self.table_name = 'issues'

    include Localizable

    # Commodity list of supported values for Issue#code.
    # To get an actual description use the helpers #label or #long_label.
    # Update descriptions inside locale files.
    #
    # === Type descriptions:
    # - 0:   request upgrade to team manager
    # - 1a:  new meeting url
    # - 1b:  report missing result
    # - 1b1: report result mistake
    # - 2b1: wrong team, swimmer or meeting attribution
    # - 3b:  change swimmer association (free select from existing swimmer)
    # - 3c:  free associated swimmer details edit
    # - 4:   generic application error/bug (w/ long description + context & desired goal)
    # - 5:   reactivate account
    SUPPORTED_CODES = %w[0 1a 1b 1b1 2b1 3b 3c 4 5].freeze

    # Limit for supported priorities (0 normal, 1 prioritized, 2 urgent, 3 critical)
    MAX_PRIORITY = 3

    # Limit status for processable issue rows.
    #
    # Setting #status to any value higher than this will flag the issue as sorted out or rejectable
    # and it will be deemed "deletable" by the cron task (once a week, allegedly).
    # Higher state values may be used to have a corresponding I18n localized verbose description for the user.
    #
    # === Supported Issue states:
    # - 0: new
    # - 1: in review
    # - 2: accepted/in process
    # - 3: accepted/paused
    # ----
    # - 4: sorted out & auto-deletable (in about a week after last row update w/ a cron task check)
    # - 5: rejected/duplicate
    # - 6: rejected/missing info or incomplete
    MAX_PROCESSABLE_STATE = 3
    #-- ------------------------------------------------------------------------
    #++

    belongs_to :user
    validates_associated :user

    validates :code, presence: { length: { within: 1..3 }, allow_nil: false },
                     uniqueness: false, inclusion: { in: SUPPORTED_CODES }

    validates :req, presence: true
    validates :priority, presence: true, numericality: true, inclusion: { in: (0..MAX_PRIORITY).to_a }
    validates :status, presence: true, numericality: true

    default_scope { includes(:user) }

    # Sorting scopes:
    scope :by_priority, ->(dir = :asc) { order(priority: dir) }
    scope :by_status,   ->(dir = :asc) { order(status: dir) }

    # Filtering scopes:
    scope :deletable,   -> { where('status > ?', MAX_PROCESSABLE_STATE) }
    scope :processable, -> { where(status: (0..MAX_PROCESSABLE_STATE).to_a) }
    scope :prioritized, -> { processable.where(priority: 1) }
    scope :urgent,      -> { processable.where(priority: 2) }
    scope :critical,    -> { processable.where(priority: 3) }

    scope :for_user,    ->(user) { where(user_id: user.id) }
    scope :for_code,    ->(code) { where(code:) }
    #-- ------------------------------------------------------------------------
    #++

    # Returns a localized #status label for this row.
    def status_label
      I18n.t("issues.status_#{status}")
    end

    # Returns +true+ if this issue row can be deleted.
    def deletable?
      status > MAX_PROCESSABLE_STATE
    end

    # Returns +true+ if this issue row can be processed.
    def processable?
      (0..MAX_PROCESSABLE_STATE).cover?(status)
    end

    # Returns +true+ if this issue row is marked as critical.
    def critical?
      priority >= 3
    end

    # Returns the extracted Hash from the #req member (assuming it contained valid JSON data).
    # Hash members will reflect the different parameters required for each different request type code.
    #
    # == Supported keys per code type:
    # All keys are stringified.
    #
    # === '0', request upgrade to team manager
    # - team_id
    # - season[] => array of all requested season IDs
    #
    # === '1a', new meeting results url (no workshops for this)
    # - meeting_id
    # - results_url
    #
    # === '1b', report missing result
    # - event_type_id
    # - swimmer_id
    # - parent_meeting_id, parent_meeting_class
    # - minutes, seconds, hundredths
    #
    # === '1b1', report result mistake
    # - result_id, result_class
    # - minutes, seconds, hundredths
    #
    # === '2b1', wrong team, swimmer or meeting attribution
    # - result_id, result_class
    # - wrong_meeting, wrong_swimmer, wrong_team => '1' when checked
    # e.g.: { "result_id"=>"1022151", "result_class"=>"MeetingIndividualResult",
    #         "wrong_meeting"=>"1", "wrong_team"=>"1" }
    #
    # === '3b', change swimmer association (free select from existing swimmer)
    # - swimmer_id
    #
    # === '3c', free associated swimmer details edit
    # - type3c_first_name, type3c_last_name
    # - type3c_year_of_birth, type3c_gender_type_id
    # e.g.: { "type3c_first_name"=>"STEFANO", "type3c_last_name"=>"ALLORO",
    #         "type3c_year_of_birth"=>"1969", "type3c_gender_type_id"=>"1" }
    #
    # === '4', generic application error/bug (w/ long description + context & desired goal)
    # - expected, outcome, reproduce => free text
    #
    # === '5', reactivate account
    # - email
    #
    def data
      parse_data if @data.nil?
      @data
    end
    #-- -----------------------------------------------------------------------
    #++

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'status_label' => status_label,
        'processable' => processable?
      )
    end

    private

    # Parses the JSON data stored in this instance #req and sets the #data Hash member.
    # Defaults to an empty Hash in case of failure.
    def parse_data
      @data = begin
        ActiveSupport::JSON.decode(req)
      rescue ActiveSupport::JSON.parse_error
        {}
      end
    end
  end
end
