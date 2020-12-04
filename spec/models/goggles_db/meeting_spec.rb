# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Meeting, type: :model do
    shared_examples_for 'a valid Meeting instance' do
      it 'is valid' do
        expect(subject).to be_a(Meeting).and be_valid
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
        'responding to a list of methods',
        %i[meeting_sessions swimming_pools pool_types event_types
           meeting_team_scores
           meeting_events meeting_programs meeting_entries meeting_individual_results meeting_relay_results
           meeting_reservations meeting_event_reservations meeting_relay_reservations
           reference_phone reference_e_mail reference_name configuration_file
           max_individual_events max_individual_events_per_session
           warm_up_pool? allows_under_25? manifest? startlist? off_season? confirmed? cancelled?
           tweeted? posted?
           results_acquired? autofilled? read_only? pb_acquired?
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { Meeting.all.limit(20).sample }
      it_behaves_like('a valid Meeting instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting) }
      it_behaves_like('a valid Meeting instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    subject { FactoryBot.create(:meeting) }

    # Sorting scopes:
    describe 'self.by_date' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', Meeting, 'date', 'header_date')
    end
    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', Meeting, 'season', 'begin_date')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#edition_label' do
      context 'for a Meeting with an ordinal edition type,' do
        subject { FactoryBot.build(:meeting, edition_type: GogglesDb::EditionType.ordinal) }
        it 'returns the label as a numeric string' do
          expect(subject.edition_label).to eq(subject.edition.to_s)
        end
      end

      context 'for a Meeting with a roman edition type,' do
        subject { FactoryBot.build(:meeting, edition_type: GogglesDb::EditionType.roman) }
        it 'returns the label as a roman numeral' do
          expect(subject.edition_label).to eq(subject.edition.to_i.to_roman)
        end
      end

      context 'for a Meeting with a seasonal or yearly edition type,' do
        subject { FactoryBot.build(:meeting, edition_type: GogglesDb::EditionType.send(%w[yearly seasonal].sample)) }
        it 'returns the header_year as label' do
          expect(subject.edition_label).to eq(subject.header_year)
        end
      end

      context 'for a Meeting with an unspecified edition type,' do
        subject { FactoryBot.build(:meeting, edition_type: GogglesDb::EditionType.none) }
        it 'returns an empty string label' do
          expect(subject.edition_label).to eq('')
        end
      end
    end

    describe '#to_json' do
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
          expect(event.meeting_session.meeting).to be_a(Meeting).and be_valid
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
