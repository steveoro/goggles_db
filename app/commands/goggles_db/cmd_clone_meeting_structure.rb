# frozen_string_literal: true

require 'simple_command'

module GogglesDb
  #
  # = Meeting structure cloner
  #
  #   - file vers.: 7.03.38
  #   - author....: Steve A.
  #   - build.....: 20211104
  #
  # Copies the structure of a given Meeting up to its MeetingProgram rows.
  #
  # Edition number will result increased & dates will be updated to the current year (where possible).
  #
  class CmdCloneMeetingStructure
    prepend SimpleCommand

    # Creates a new command object given the parameters.
    #
    # == Parameters:
    # - +meeting+: the source +Meeting+ to clone.
    # - +dest_season+: the +Season+ to clone the +Meeting+ into; defaults to the same season as the source meeting.
    #
    def initialize(meeting, dest_season = nil)
      @meeting = meeting
      @dest_season = dest_season || (meeting.respond_to?(:season) ? meeting.season : nil)
    end

    # Sets #result to the newly created Meeting when successful.
    # Always returns itself.
    def call
      return unless internal_members_valid?

      # Clone meeting head -> session(s) -> events x session -> programs x event:
      result_meeting = clone_meeting_head
      deep_clone_sessions(result_meeting)

      result_meeting
    end

    private

    # Checks validity of the constructor parameters; returns +false+ in case of error.
    def internal_members_valid?
      return true if @meeting.instance_of?(GogglesDb::Meeting) && @meeting.valid? &&
                     @dest_season.instance_of?(GogglesDb::Season) && @dest_season.valid?

      errors.add(:msg, 'Invalid constructor parameters')
      false
    end

    # Computes the difference in years between the 'header_date' and today.
    def date_diff_in_years_from_today
      @date_diff_in_years_from_today ||= (Time.zone.today.year - @meeting.header_date.year).years
    end

    # Computes the updated 'header_year' field in SHORT format, assuming the new cloned Meeting will
    # take place in the current year.
    #
    # - SHORT format...: "YYYY", for special Meetings occurring once per year, like any National or
    #                    International Championships.
    #
    def updated_header_year_short
      Time.zone.today.year.to_s
    end

    # Computes the updated 'header_year' field in LONG format, assuming the new cloned Meeting will
    # take place in the current year.
    #
    # - LONG format....: "YYYY/YYYY+1" (most common), for Meetings occurring in Championships Seasons
    #                    typically spanning Autumn .. Spring.
    #
    def updated_header_year_long
      # Find out where the original year was located inside the long format and recreate it
      # depending on position:
      year_idx = Regexp.new(@meeting.header_date.year.to_s) =~ @meeting.header_year

      if year_idx&.positive?
        "#{Time.zone.today.year - 1}/#{Time.zone.today.year}"
      else
        "#{Time.zone.today.year}/#{Time.zone.today.year + 1}"
      end
    end

    # Filters out ID, timestamps, lock columns...
    def reject_common_columns(attribute_hash)
      attribute_hash.reject { |key, _value| %w[id lock_version created_at updated_at season_id].include?(key) }
    end

    # Clones the Meeting master row, clearing out some of its attributes.
    def clone_meeting_head
      GogglesDb::Meeting.create!(
        reject_common_columns(@meeting.attributes)
          .merge(
            edition: @meeting.edition + 1, # (Assuming this will be the next edition of the source meeting)
            entry_deadline: nil,
            header_date: @meeting.header_date + date_diff_in_years_from_today,
            header_year: @meeting.header_year.to_s.size < 5 ? updated_header_year_short : updated_header_year_long,
            season_id: @dest_season.id,
            manifest_body: nil,
            manifest: false,
            startlist: false,
            autofilled: false,
            confirmed: false,
            tweeted: false,
            posted: false,
            cancelled: false,
            pb_acquired: false,
            read_only: false
          )
      )
    end

    # Deep-clones all the Meeting sessions from the source Meeting into the specified destination.
    # For each session, deep-clones its events.
    def deep_clone_sessions(dest_meeting)
      @meeting.meeting_sessions.each do |meeting_session|
        dest_meeting_session = GogglesDb::MeetingSession.create!(
          reject_common_columns(meeting_session.attributes)
            .merge(
              meeting_id: dest_meeting.id,
              scheduled_date: dest_meeting.header_date,
              autofilled: false
            )
        )
        deep_clone_events(meeting_session, dest_meeting_session)
      end
    end

    # Deep-clones all the Meeting events from the source MeetingSession into the specified destination.
    # For each event, clones its programs.
    def deep_clone_events(meeting_session, dest_meeting_session)
      meeting_session.meeting_events.each do |meeting_event|
        dest_meeting_event = GogglesDb::MeetingEvent.create!(
          reject_common_columns(meeting_event.attributes)
            .merge(
              meeting_session_id: dest_meeting_session.id,
              autofilled: false
            )
        )
        clone_programs(meeting_event, dest_meeting_event)
      end
    end

    # Clones all the Meeting programs from the source MeetingEvent into the specified destination.
    def clone_programs(meeting_event, dest_meeting_event)
      meeting_event.meeting_programs.each do |meeting_program|
        GogglesDb::MeetingProgram.create!(
          reject_common_columns(meeting_program.attributes)
            .merge(
              meeting_event_id: dest_meeting_event.id,
              autofilled: false
            )
        )
      end
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
