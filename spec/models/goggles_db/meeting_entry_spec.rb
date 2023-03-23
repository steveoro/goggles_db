# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingEntry do
    shared_examples_for 'a valid MeetingEntry instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_program team team_affiliation
           meeting meeting_session meeting_event
           event_type category_type gender_type]
      )

      # Presence of fields:
      it_behaves_like(
        'responding to a list of methods',
        %i[pool_type
           start_list_number lane_number heat_number heat_arrival_order
           minutes seconds hundredths
           swimmer badge entry_time_type
           relay? intermixed? male? female?
           no_time? to_timing
           minimal_attributes meeting_attributes meeting_session_attributes
           to_json]
      )
    end

    context 'any valid, pre-seeded instance' do
      # [Steve A.] Make sure data errors don't create random failures by joining w/ M.Progs:
      # (It may happen w/ older data dumps)
      subject { described_class.joins(:meeting_program).last(20).sample }

      it_behaves_like('a valid MeetingEntry instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_entry) }

      it_behaves_like('a valid MeetingEntry instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_swimmer' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'swimmer', 'complete_name')
    end

    describe 'self.by_number' do
      let(:fixture_prg) do
        prg = FactoryBot.create(:meeting_program)
        FactoryBot.create_list(:meeting_entry, 5, meeting_program: prg)
        expect(prg.meeting_entries.count).to eq(5)
        prg
      end
      let(:result) { fixture_prg.meeting_entries.by_number }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'start_list_number')
    end

    describe 'self.by_split_gender' do
      let(:fixture_event) do
        event = FactoryBot.create(:meeting_event_individual)
        prg_male = FactoryBot.create(:meeting_program_individual, meeting_event: event, gender_type: GogglesDb::GenderType.male)
        prg_female = FactoryBot.create(:meeting_program_individual, meeting_event: event, gender_type: GogglesDb::GenderType.female)
        FactoryBot.create_list(:meeting_entry, 3, meeting_program: prg_male)
        FactoryBot.create_list(:meeting_entry, 3, meeting_program: prg_female)
        expect(prg_male.meeting_entries.count).to eq(3)
        expect(prg_female.meeting_entries.count).to eq(3)
        expect(event.meeting_entries.count).to eq(6)
        event
      end
      let(:result) { fixture_event.meeting_entries.by_split_gender }

      before { expect(fixture_event).to be_a(MeetingEvent).and be_valid }

      it 'is a MeetingEntry relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
      end

      context 'each gender group' do
        let(:female_entries) { result.to_a[0..2] }
        let(:male_entries)   { result.to_a[3..5] }

        it 'is correctly split by gender' do
          expect(female_entries).to all(be_female)
          expect(male_entries).to all(be_male)
        end

        it 'is ordered by descending timing in itself' do
          expect(female_entries.first.to_timing).to be >= female_entries.second.to_timing
          expect(female_entries.second.to_timing).to be >= female_entries.third.to_timing
          expect(male_entries.first.to_timing).to be >= male_entries.second.to_timing
          expect(male_entries.second.to_timing).to be >= male_entries.third.to_timing
        end
      end
    end

    # Filtering scopes:
    describe 'self.for_gender_type' do
      it_behaves_like(
        'filtering scope for_<ANY_CHOSEN_FILTER>',
        described_class,
        'for_gender_type',
        'gender_type',
        GogglesDb::GenderType.send(%w[male female].sample)
      )
    end

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end

    describe 'self.for_category_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'category_type')
    end

    describe 'self.for_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'event_type')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:meeting_entry) }

      it_behaves_like 'TimingManageable'
    end

    describe '#minimal_attributes' do
      subject { existing_row.minimal_attributes }

      let(:existing_row) { described_class.limit(100).sample }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      it 'includes the timing string' do
        expect(subject['timing']).to eq(existing_row.to_timing.to_s)
      end

      %w[team team_affiliation swimmer pool_type event_type category_type gender_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_entry) }

      it 'includes the timing string' do
        expect(JSON.parse(subject.to_json)['timing']).to eq(subject.to_timing.to_s)
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_program team team_affiliation pool_type event_type category_type gender_type]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting meeting_session]
      )

      # Optional associations:
      context 'when the entity contains other optional associations,' do
        # (The default factory already has all the optional associations)
        let(:json_hash) do
          expect(subject.swimmer).to be_a(Swimmer).and be_valid
          JSON.parse(subject.to_json)
        end

        it_behaves_like(
          '#to_json when the entity contains other optional associations with',
          %w[swimmer]
        )
      end
    end
  end
end
