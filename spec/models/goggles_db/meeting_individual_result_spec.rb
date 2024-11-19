# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_result_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe MeetingIndividualResult do
    shared_examples_for 'a valid MeetingIndividualResult instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Tests the validity of the default_scope when there's an optional association involved:
      it 'does not raise errors when selecting a random row with a field name' do
        %w[disqualification_code_type_id team_affiliation_id badge_id].each do |field_name|
          expect { described_class.unscoped.select(field_name).limit(100).sample }.not_to raise_error
        end
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season season_type meeting meeting_session meeting_event meeting_program
           pool_type event_type category_type gender_type federation_type stroke_type]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[rank standard_points meeting_points goggle_cup_points team_points
           reaction_time minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[team_name team_editable_name
           length_in_meters
           out_of_race? disqualified? personal_best?
           valid_for_ranking? to_timing
           meeting_attributes meeting_session_attributes swimmer_attributes]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.last(20).sample }

      it_behaves_like('a valid MeetingIndividualResult instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_individual_result) }

      it_behaves_like('a valid MeetingIndividualResult instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    it_behaves_like('AbstractResult sorting scopes', described_class)

    describe 'self.by_date' do
      let(:result) do
        mirs = described_class.where(swimmer_id: 142).by_date.limit(50)
        expect(mirs.count).to be_positive
        mirs
      end

      it 'is a MeetingIndividualResult relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
      end

      it 'is ordered' do
        expect(result.first.meeting_session.scheduled_date).to be <= result.sample.meeting_session.scheduled_date
        expect(result.sample.meeting_session.scheduled_date).to be <= result.last.meeting_session.scheduled_date
      end
    end

    # Filtering scopes:
    it_behaves_like('AbstractResult filtering scopes', described_class)

    describe 'self.valid_for_ranking' do
      let(:result) { subject.class.valid_for_ranking.order('out_of_race DESC, disqualified DESC').limit(20) }

      it 'contains only results valid for ranking' do
        expect(result).to all(be_valid_for_ranking)
      end
    end

    describe 'self.personal_bests' do
      let(:result) { subject.class.personal_bests.limit(20) }

      it 'contains only personal-best timing results' do
        expect(result).to all(be_personal_best)
      end
    end

    describe 'self.for_meeting_code' do
      let(:meeting_filter) do
        # Filter out unique IDs quick, then load the whole row:
        Meeting.includes(:meeting_individual_results).joins(:meeting_individual_results)
               .distinct(:id).limit(20).sample
      end
      let(:result) { described_class.for_meeting_code(meeting_filter).limit(20) }

      it 'is a relation containing only MeetingIndividualResults associated to the filter' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
        list_of_meeting_codes = result.map { |mir| mir.meeting.code }.uniq.sort
        expect(list_of_meeting_codes).to eq([meeting_filter.code])
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#valid_for_ranking?' do
      context 'for any MIR concurring in-race, not disqualified and with positive time' do
        subject { mir_fixture.valid_for_ranking? }

        let(:mir_fixture) { FactoryBot.build(:meeting_individual_result, out_of_race: false, disqualified: false) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'for any MIR either off-race or disqualified' do
        subject { mir_fixture.valid_for_ranking? }

        let(:mir_fixture) { FactoryBot.build(:meeting_individual_result, out_of_race: true, disqualified: [false, true].sample) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:meeting_individual_result) }

      it_behaves_like 'TimingManageable'
    end
    #-- ------------------------------------------------------------------------
    #++

    it_behaves_like(
      'AbstractResult #minimal_attributes',
      described_class,
      %w[swimmer team_affiliation disqualification_code_type]
    )

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.last(200).sample }

      it 'includes the team name & decorated label' do
        expect(result['team_name']).to eq(fixture_row.team.editable_name)
        expect(result['team_label']).to eq(fixture_row.team.decorate.display_label)
      end

      it 'includes the event label' do
        expect(result['event_label']).to eq(fixture_row.event_type.label)
      end

      it 'includes the category code & label' do
        expect(result['category_code']).to eq(fixture_row.category_type.code)
        expect(result['category_label']).to eq(fixture_row.category_type.decorate.short_label)
      end

      it 'includes the gender code' do
        expect(result['gender_code']).to eq(fixture_row.gender_type.code)
      end
    end

    describe '#to_hash' do
      subject { described_class.last(20).sample }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[meeting_program team team_affiliation pool_type event_type category_type gender_type stroke_type]
      )
      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[meeting meeting_session swimmer]
      )

      # Optional associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 optional association with',
        %w[disqualification_code_type]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject { described_class.joins(:laps).last(20).sample }

        it_behaves_like(
          '#to_hash when the entity has any 1:N collection association with',
          %w[laps]
        )
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
