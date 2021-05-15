# frozen_string_literal: true

module GogglesDb
  #
  # = DayPartType model
  #
  # This entity is assumed to be pre-seeded on the database.
  #
  #   - version:  7.035
  #   - authors:  Steve A.
  #
  class DisqualificationCodeType < AbstractLookupEntity
    self.table_name = 'disqualification_code_types'

    validates :code, presence: { length: { within: 1..4 }, allow_nil: false },
                     uniqueness: { case_sensitive: true, message: :already_exists }

    belongs_to :stroke_type, optional: true
    #-- ------------------------------------------------------------------------
    #++

    # Returns +true+ if the code refers to a generic "false start".
    def false_start?
      code == 'GA'
    end

    # Returns +true+ if the code refers to a generic "retired from event".
    def retired?
      code == 'GK'
    end
  end
end
