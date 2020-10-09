# frozen_string_literal: true

module GogglesDb
  #
  # = Swimmer model
  #
  #   - version:  7.008
  #   - author:   Steve A.
  #
  class Swimmer < ApplicationRecord
    self.table_name = 'swimmers'

    # Actual User row associated with this Swimmer. It can be nil.
    belongs_to :associated_user, class_name: 'User', optional: true,
                                 foreign_key: 'associated_user_id'
    # Legacy link to creator or editor; it can be nil:
    belongs_to :user

    belongs_to            :gender_type
    validates_associated  :gender_type

    validates :complete_name, presence: true, length: { within: 1..100, allow_nil: false }
    validates :last_name, length: { maximum: 50 }
    validates :first_name, length: { maximum: 50 }
    validates :year_of_birth, presence: true, length: { within: 2..4, allow_nil: false }

    delegate :male?, :female?, :intermixed?, to: :gender_type

    alias_attribute :year_guessed?, :is_year_guessed
    #-- ------------------------------------------------------------------------
    #++

    # Override: includes all 1st-level associations into the typical to_json output.
    def to_json(options = nil)
      attributes.merge(
        'associated_user' => associated_user&.attributes,
        'gender_type' => gender_type.attributes
      ).to_json(options)
    end
  end
end
