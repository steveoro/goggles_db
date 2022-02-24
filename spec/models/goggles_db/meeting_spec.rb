# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'
require 'support/shared_abstract_meeting_examples'

module GogglesDb
  RSpec.describe Meeting, type: :model do
    subject { FactoryBot.create(:meeting) }

    shared_examples_for 'a valid Meeting instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season season_type federation_type edition_type timing_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[code header_year edition description]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[by_date by_season for_name
           team_presence? swimmer_presence?]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[meeting_sessions swimming_pools pool_types event_types
           meeting_team_scores
           meeting_events meeting_programs meeting_entries meeting_individual_results meeting_relay_results
           meeting_reservations meeting_event_reservations meeting_relay_reservations
           reference_phone reference_e_mail reference_name configuration_file
           home_team
           season edition_type timing_type
           max_individual_events max_individual_events_per_session
           warm_up_pool? allows_under25? manifest? startlist? off_season? confirmed? cancelled?
           tweeted? posted?
           results_acquired? autofilled? read_only? pb_acquired?
           tags_by_user_list tags_by_team_list
           edition_label minimal_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid Meeting instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting) }

      it_behaves_like('a valid Meeting instance')
    end

    # Sorting scopes:
    describe 'self.by_date' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'date', 'header_date')
    end

    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'begin_date')
    end

    # Filtering scopes:
    describe 'self.not_cancelled' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER> with no parameters', described_class, 'not_cancelled',
                      'cancelled', false)
    end

    describe 'self.for_season_type' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season_type',
                      'season_type', GogglesDb::SeasonType.all_masters.sample)
    end

    describe 'self.for_code' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_code', 'code',
                      %w[csiprova1 csiprova2 italiani europei regemilia riccione].sample)
    end

    describe 'self.only_manifest' do
      context 'when there are Meeting rows having the meeting manifest w/o acquired results,' do
        before { FactoryBot.create_list(:meeting, 5, manifest: true, results_acquired: false) }

        let(:result) { described_class.only_manifest.limit(10) }

        it 'is a relation containing only Meetings having the manifest flag set' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)
          expect(result.map(&:manifest).uniq).to all be true
          expect(result.map(&:results_acquired).uniq).to all be false
        end
      end
    end

    describe 'self.only_startlist' do
      context 'when there are Meeting rows having the meeting startlist w/o acquired results,' do
        before { FactoryBot.create_list(:meeting, 5, startlist: true, results_acquired: false) }

        let(:result) { described_class.only_startlist.limit(10) }

        it 'is a relation containing only Meetings having the startlist flag set' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)
          expect(result.map(&:startlist).uniq).to all be true
          expect(result.map(&:results_acquired).uniq).to all be false
        end
      end
    end

    describe 'self.with_results' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER> with no parameters', described_class, 'with_results',
                      'results_acquired', true)
    end

    describe 'self.without_results' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER> with no parameters', described_class, 'without_results',
                      'results_acquired', false)
    end

    describe 'self.not_closed' do
      context 'when there are Meeting rows having the header_date set in the future,' do
        before { FactoryBot.create_list(:meeting, 5, header_date: Time.zone.today + 2.months, results_acquired: false) }

        let(:result) { described_class.not_closed.limit(10) }

        it 'is a relation containing only Meetings having the header_date set in the future' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)
          expect(
            result.map(&:header_date).uniq
          ).to all be > Time.zone.today
          expect(result.map(&:results_acquired).uniq).to all be false
        end
      end
    end

    describe 'self.still_open_at(date)' do
      context 'when there are Meeting rows having the header_date AND the entry_deadline set in the future,' do
        before { FactoryBot.create_list(:meeting, 5, header_date: Time.zone.today + 2.months) }

        let(:result) { described_class.still_open_at(Time.zone.today).limit(10) }

        it 'is a relation containing only Meetings having the header_date set in the future' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)
          expect(
            result.map(&:header_date).uniq
          ).to all be > Time.zone.today
          expect(result.map(&:results_acquired).uniq).to all be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.for_name' do
      context 'when combined with other associations that include same-named columns,' do
        subject do
          described_class.joins(meeting_sessions: :swimming_pool)
                         .includes(meeting_sessions: :swimming_pool)
                         .for_name(%w[riccione CSI reggio parma].sample)
        end

        it 'does not raise errors' do
          expect { subject.count }.not_to raise_error
        end
      end

      %w[riccione reggio parma deakker bologna ravenna].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_name, %w[description code], filter_text)
      end
    end

    describe 'self.for_team' do
      let(:chosen_filter) do
        described_class.includes(:meeting_individual_results).joins(:meeting_individual_results)
                       .select(:team_id).distinct
                       .limit(20).sample
                       .meeting_individual_results.first
                       .team
      end

      context 'when combined with other associations that include same-named columns,' do
        subject do
          described_class.joins(:meeting_team_scores, :meeting_reservations)
                         .includes(:meeting_team_scores, :meeting_reservations)
                         .for_team(chosen_filter)
        end

        it 'does not raise errors' do
          expect { subject.count }.not_to raise_error
        end
      end

      context "given the chosen Team has any #{described_class.to_s.pluralize} associated to it," do
        let(:result) { described_class.for_team(chosen_filter).limit(10) }

        it 'is a relation containing only Meetings attended by the specified Team' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)

          all_rows_have_same_team = result.all? do |meeting|
            GogglesDb::MeetingIndividualResult.includes(:meeting).joins(:meeting)
                                              .exists?('meetings.id': meeting.id, team_id: chosen_filter.id) ||
              GogglesDb::MeetingRelayResult.includes(:meeting).joins(:meeting)
                                           .exists?('meetings.id': meeting.id, team_id: chosen_filter.id)
          end
          expect(all_rows_have_same_team).to be true
        end
      end
    end

    describe 'self.for_swimmer' do
      let(:chosen_filter) do
        described_class.includes(:meeting_relay_swimmers).joins(:meeting_relay_swimmers)
                       .select(:swimmer_id).distinct
                       .limit(20).sample
                       .meeting_relay_swimmers.first
                       .swimmer
      end

      context 'when combined with other associations that include same-named columns,' do
        subject do
          described_class.joins(:meeting_relay_swimmers).includes(:meeting_relay_swimmers)
                         .for_swimmer(chosen_filter)
        end

        it 'does not raise errors' do
          expect { subject.count }.not_to raise_error
        end
      end

      context "given the chosen Swimmer has any #{described_class.to_s.pluralize} associated to it," do
        let(:result) { described_class.send('for_swimmer', chosen_filter).limit(10) }

        it 'is a relation containing only Meetings attended by the specified Swimmer' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)

          all_rows_have_same_swimmer = result.all? do |meeting|
            GogglesDb::MeetingIndividualResult.includes(:meeting).joins(:meeting)
                                              .exists?('meetings.id': meeting.id, swimmer_id: chosen_filter.id) ||
              GogglesDb::MeetingRelaySwimmer.includes(:meeting).joins(:meeting)
                                            .exists?('meetings.id': meeting.id, swimmer_id: chosen_filter.id)
          end
          expect(all_rows_have_same_swimmer).to be true
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.team_presence?' do
      let(:chosen_result) do
        described_class.includes(:meeting_individual_results).joins(:meeting_individual_results)
                       .select(:team_id).distinct
                       .limit(20).sample
                       .meeting_individual_results.sample
      end
      let(:chosen_meeting) { chosen_result.meeting }
      let(:chosen_team) { chosen_result.team }
      let(:fixture_team) { FactoryBot.create(:team) }

      context 'when the chosen meeting has any results or presence of the chosen team,' do
        it 'returns true' do
          expect(described_class.team_presence?(chosen_meeting, chosen_team)).to be true
        end
      end

      context 'when the chosen meeting does NOT have any results or presence of the chosen team,' do
        it 'returns false' do
          expect(described_class.team_presence?(chosen_meeting, fixture_team)).to be false
        end
      end
    end

    describe 'self.swimmer_presence?' do
      let(:chosen_result) do
        described_class.includes(:meeting_individual_results).joins(:meeting_individual_results)
                       .select(:swimmer_id).distinct
                       .limit(20).sample
                       .meeting_individual_results.sample
      end
      let(:chosen_meeting) { chosen_result.meeting }
      let(:chosen_swimmer) { chosen_result.swimmer }
      let(:fixture_swimmer) { FactoryBot.create(:swimmer) }

      context 'when the chosen meeting has any results or presence of the chosen swimmer,' do
        it 'returns true' do
          expect(described_class.swimmer_presence?(chosen_meeting, chosen_swimmer)).to be true
        end
      end

      context 'when the chosen meeting does NOT have any results or presence of the chosen swimmer,' do
        it 'returns false' do
          expect(described_class.swimmer_presence?(chosen_meeting, fixture_swimmer)).to be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    it_behaves_like('AbstractMeeting #edition_label', :meeting)
    it_behaves_like('AbstractMeeting #name_without_edition', :meeting)
    it_behaves_like('AbstractMeeting #name_with_edition', :meeting)
    it_behaves_like('AbstractMeeting #condensed_name', :meeting)

    it_behaves_like('AbstractMeeting #minimal_attributes', described_class)

    describe '#to_json' do
      # Required keys:
      %w[
        display_label short_label edition_label
        season edition_type timing_type season_type federation_type
      ].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(subject.to_json[member_name]).to be_present
        end
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[season edition_type timing_type season_type federation_type]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject do
          # Use existing data to get a Meeting that already has events:
          event = GogglesDb::MeetingEvent.limit(200).sample
          expect(event.meeting_session.meeting).to be_a(described_class).and be_valid
          event.meeting_session.meeting
        end

        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[meeting_sessions meeting_events]
        )
      end
    end
  end
end
