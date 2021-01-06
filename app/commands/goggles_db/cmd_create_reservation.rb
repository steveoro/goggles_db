# frozen_string_literal: true

require 'simple_command'

module GogglesDb
  #
  # = Creator command for MeetingReservations
  #
  #   - file vers.: 1.58
  #   - author....: Steve A.
  #   - build.....: 20210106
  #
  # Allows to create a single MeetingReservation header row together with its associated
  # event & relay reservations for a single swimmer (badge) at a given Meeting.
  #
  # Given a list of badges or swimmers that allegedly have to attend a specific Meeting,
  # this command object can be used to create the whole "reservation matrix" for a team just by
  # running it iteratively on each current badge of the team.
  #
  # Typically this should be an action issued by a Team Manager (or any other user enabled to do so).
  #
  # It will be then be responsibility of the individual swimmer to confirm or select which
  # event has been chosen for enrollment (and registration).
  #
  class CmdCreateReservation
    prepend SimpleCommand

    # Creates a new command object given the parameters.
    # The associated events & relays will be created according to the current
    # setup of the meeting.
    # The default timings will be retrieved using a dedicated strategy object.
    def initialize(badge, meeting, current_user)
      @badge = badge
      @meeting = meeting
      @current_user = current_user
    end

    # Sets #result to the created MeetingReservation when successful.
    # Always returns itself.
    def call
      return unless internal_members_valid?

      result = create_master_row
      return if result.nil?

      @meeting.meeting_events.each do |meeting_event|
        if meeting_event.relay?
          create_detail_relay_row(result, meeting_event)
        else
          create_detail_event_row(result, meeting_event)
        end
      end

      result
    end

    private

    # Checks validity of the constructor parameters; returns +false+ in case of error.
    def internal_members_valid?
      return true if @badge.instance_of?(GogglesDb::Badge) && @meeting.instance_of?(GogglesDb::Meeting) && @current_user.instance_of?(GogglesDb::User)

      errors.add(:msg, 'Invalid constructor parameters')
      false
    end

    # Returns the master reservation row, +nil+ in case of errors.
    #
    def create_master_row
      GogglesDb::MeetingReservation.create!(
        user_id: @current_user.id,
        meeting_id: @meeting.id,
        team_id: @badge.team_id,
        swimmer_id: @badge.swimmer_id,
        badge_id: @badge.id,
        not_coming: false,
        confirmed: false
      )
    rescue ActiveRecord::RecordNotUnique
      errors.add(:msg, 'Duplicate master MeetingReservation: not saved')
      nil
    end

    # Returns a new event reservation row, +nil+ in case of errors.
    #
    def prepare_common_options_for_event_detail(master_row, meeting_event)
      {
        meeting_id: @meeting.id,
        team_id: @badge.team_id,
        swimmer_id: @badge.swimmer_id,
        badge_id: @badge.id,
        meeting_event_id: meeting_event.id,
        accepted: false,
        meeting_reservation_id: master_row.id
      }
    end

    # Returns a new event reservation row, +nil+ in case of errors.
    #
    def create_detail_event_row(master_row, meeting_event)
      # Retrieve a default/suggested timing for the entry using a dedicated strategy.
      # The strategy relies on the EntryTimeType value stored on the @badge.
      cmd = CmdFindEntryTime.call(@badge.swimmer, @meeting, meeting_event.event_type, meeting_event.pool_type, @badge.entry_time_type)
      entry_timing = cmd.success? ? cmd.result : Timing.new

      GogglesDb::MeetingEventReservation.create!(
        prepare_common_options_for_event_detail(master_row, meeting_event)
          .merge(
            minutes: entry_timing.minutes,
            seconds: entry_timing.minutes,
            hundreds: entry_timing.minutes
          )
      )
    rescue ActiveRecord::RecordNotUnique
      errors.add(:msg, 'Duplicate detail MeetingEventReservation: not saved')
      nil
    end

    # Returns a new relay reservation row, +nil+ in case of errors.
    #
    def create_detail_relay_row(master_row, meeting_event)
      GogglesDb::MeetingRelayReservation.create!(
        prepare_common_options_for_event_detail(master_row, meeting_event)
      )
    rescue ActiveRecord::RecordNotUnique
      errors.add(:msg, 'Duplicate detail MeetingRelayReservation: not saved')
      nil
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
