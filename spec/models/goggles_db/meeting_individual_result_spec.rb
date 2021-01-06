# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingIndividualResult, type: :model do
    shared_examples_for 'a valid MeetingIndividualResult instance' do
      it 'is valid' do
        expect(subject).to be_a(MeetingIndividualResult).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season season_type meeting meeting_session meeting_event meeting_program
           pool_type event_type category_type gender_type federation_type stroke_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[rank standard_points meeting_individual_points goggle_cup_points team_points reaction_time]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[out_of_race? disqualified? personal_best?
           valid_for_ranking? to_timing to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { MeetingIndividualResult.all.limit(20).sample }
      it_behaves_like('a valid MeetingIndividualResult instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_individual_result) }
      it_behaves_like('a valid MeetingIndividualResult instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    # TODO: by_rank, by_date, by_timing

    # describe 'self.by_event_type' do
    #   it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'event_type', 'code')
    # end
    # describe 'self.by_category_type' do
    #   it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'category_type', 'code')
    # end

    # Filtering scopes:
    describe 'self.valid_for_ranking' do
      let(:result) { subject.class.valid_for_ranking.order('out_of_race DESC, disqualified DESC').limit(20) }
      it 'contains only results valid for ranking' do
        expect(result).to all(be_valid_for_ranking)
      end
    end
    describe 'self.qualifications' do
      let(:result) { subject.class.qualifications.order('disqualified DESC').limit(20) }
      it 'contains only qualified results' do
        expect(result.map(&:disqualified?).uniq).to all(be false)
      end
    end
    describe 'self.disqualifications' do
      let(:result) { subject.class.disqualifications.limit(20) }
      it 'contains only qualified results' do
        expect(result).to all(be_disqualified)
      end
    end
    describe 'self.personal_bests' do
      let(:result) { subject.class.personal_bests.limit(20) }
      it 'contains only personal-best timing results' do
        expect(result).to all(be_personal_best)
      end
    end
    describe 'self.for_gender_type' do
      it_behaves_like('filtering scope for_gender_type', MeetingIndividualResult)
    end

    describe 'self.for_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'event_type')
    end
    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'pool_type')
    end
    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'swimmer')
    end

    describe 'self.for_meeting_code' do
      let(:meeting_filter) do
        # Filter out unique IDs quick, then load the whole row:
        meeting_id = Meeting.joins(meeting_events: :meeting_individual_results).select(:id).distinct.limit(20).sample.id
        Meeting.find(meeting_id)
      end
      let(:result) { MeetingIndividualResult.for_meeting_code(meeting_filter).limit(20) }

      it 'is a relation containing only MeetingIndividualResults associated to the filter' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(MeetingIndividualResult)
        list_of_meeting_codes = result.map { |mir| mir.meeting.code }.uniq.sort
        expect(list_of_meeting_codes).to eq([meeting_filter.code])
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#valid_for_ranking?' do
      context 'for any MIR concurring in-race and not disqualified' do
        let(:mir_fixture) { FactoryBot.build(:meeting_individual_result, out_of_race: false, disqualified: false) }
        subject { mir_fixture.valid_for_ranking? }
        it 'is true' do
          expect(subject).to be true
        end
      end
      context 'for any MIR either off-race or disqualified' do
        let(:mir_fixture) { FactoryBot.build(:meeting_individual_result, out_of_race: true, disqualified: [false, true].sample) }
        subject { mir_fixture.valid_for_ranking? }
        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:meeting_individual_result) }
      it_behaves_like 'TimingManageable'
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_individual_result) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_program pool_type event_type category_type gender_type stroke_type]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting meeting_session]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject         { FactoryBot.create(:meeting_individual_result_with_laps) }
        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[laps]
        )
      end
    end
  end
end
