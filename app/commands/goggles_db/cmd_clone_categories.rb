# frozen_string_literal: true

require 'simple_command'

module GogglesDb
  #
  # = Meeting structure cloner
  #
  #   - file vers.: 7.03.01
  #   - author....: Steve A.
  #   - build.....: 20210614
  #
  # Copies the structure of a given Meeting up to its MeetingProgram rows.
  #
  # Edition number will result increased & dates will be updated to the current year (where possible).
  #
  class CmdCloneCategories
    prepend SimpleCommand

    # Clones the whole list of existing CategoryTypes from one Season to another.
    #
    def initialize(from_season, to_season)
      @from_season = from_season
      @to_season = to_season
    end

    # Sets #result to the ActiveRecord association of all the created CategoryTypes.
    # Always returns itself.
    def call
      return unless internal_members_valid?

      @from_season.category_types.each do |category_type|
        GogglesDb::CategoryType.create!(
          reject_common_columns(category_type.attributes)
            .merge(season_id: @to_season.id)
        )
      end

      GogglesDb::CategoryType.where(season_id: @to_season.id)
    end

    private

    # Checks validity of the constructor parameters; returns +false+ in case of error.
    def internal_members_valid?
      return true if @from_season.instance_of?(GogglesDb::Season) && @from_season.valid? &&
                     @to_season.instance_of?(GogglesDb::Season) && @to_season.valid?

      errors.add(:msg, 'Invalid constructor parameters')
      false
    end

    # Filters out ID, timestamps, lock columns...
    def reject_common_columns(attribute_hash)
      attribute_hash.except('id', 'lock_version', 'created_at', 'updated_at')
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
