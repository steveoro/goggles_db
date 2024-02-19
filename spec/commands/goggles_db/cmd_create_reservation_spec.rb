# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdCreateReservation, type: :command do
    let(:fixture_meeting) do
      # To assure that the selected meeting has indeed events, we'll start from the
      # events themselves:
      mev = GogglesDb::MeetingEvent.includes(:meeting).joins(:meeting).limit(200).sample
      mev.meeting
    end
    let(:fixture_user)     { GogglesDb::User.limit(30).sample }
    let(:fixture_season)   { fixture_meeting.season }
    let(:fixture_team_aff) { fixture_season.team_affiliations.sample }
    let(:fixture_category) { fixture_season.category_types.sample }
    let(:fixture_swimmer)  { FactoryBot.create(:swimmer) }
    let(:fixture_badge) do
      FactoryBot.create(
        :badge,
        swimmer: fixture_swimmer,
        category_type: fixture_category,
        team_affiliation: fixture_team_aff,
        season: fixture_season,
        team: fixture_team_aff.team
      )
    end
    # Make sure domain is coherent with expected context:

    before do
      expect(fixture_user).to be_a(GogglesDb::User).and be_valid
      expect(fixture_meeting).to be_a(GogglesDb::Meeting).and be_valid
      expect(fixture_meeting.meeting_events.count).to be_positive
      expect(fixture_season).to be_a(GogglesDb::Season).and be_valid
      expect(fixture_team_aff).to be_a(GogglesDb::TeamAffiliation).and be_valid
      expect(fixture_swimmer).to be_a(GogglesDb::Swimmer).and be_valid
      expect(fixture_category).to be_a(GogglesDb::CategoryType).and be_valid
      expect(fixture_badge).to be_a(GogglesDb::Badge).and be_valid
    end

    context 'when using valid parameters (including a Meeting w/ events),' do
      describe '#call' do
        # This will select one of the already populated Meetings (with events & categories):
        subject { Prosopite.pause { described_class.call(fixture_badge, fixture_meeting, fixture_user) } }

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'is successful' do
          expect(subject).to be_successful
        end

        it 'has a blank #errors list' do
          expect(subject.errors).to be_blank
        end

        it 'has a valid MeetingReservation #result' do
          expect(subject.result).to be_a(GogglesDb::MeetingReservation).and be_valid
        end

        it 'creates the same number of event rows as the specified Meeting' do
          expect(
            subject.result.meeting_event_reservations.count +
            subject.result.meeting_relay_reservations.count
          ).to eq(fixture_meeting.meeting_events.count)
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using valid constructor parameters but that would yield a duplicated MeetingReservation,' do
      describe '#call' do
        subject { Prosopite.pause { described_class.call(existing_row.badge, existing_row.meeting, existing_row.user) } }

        let(:existing_row) { GogglesDb::MeetingReservation.limit(30).sample }

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a non-empty #errors list displaying a error message about header creation failure' do
          expect(subject.errors).to be_present
          expect(subject.errors[:msg]).to eq(['Duplicate master MeetingReservation: not saved'])
        end

        it 'has a nil #result' do
          expect(subject.result).to be_nil
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid constructor parameters,' do
      describe '#call' do
        subject do
          option = [fixture_badge, fixture_meeting, fixture_user]
          # Make a random item invalid for the constructor:
          option[(rand * 10 % 3).to_i] = nil
          described_class.call(option[0], option[1], option[2])
        end

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a non-empty #errors list displaying a error message about constructor parameters' do
          expect(subject.errors).to be_present
          expect(subject.errors[:msg]).to eq(['Invalid constructor parameters'])
        end

        it 'has a nil #result' do
          expect(subject.result).to be_nil
        end
      end
    end
  end
end
