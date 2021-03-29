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
        %i[rank standard_points meeting_points goggle_cup_points team_points reaction_time]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[out_of_race? disqualified? personal_best?
           valid_for_ranking? to_timing
           meeting_attributes meeting_session_attributes swimmer_attributes
           minimal_attributes to_json]
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
    describe 'self.by_rank' do
      let(:result) do
        # Choose a sample MPrg for which we are sure there will be multiple MIRs:
        mprg = GogglesDb::MeetingProgram.includes(:meeting_individual_results, :event_type)
                                        .joins(:meeting_individual_results, :event_type)
                                        .where('event_types.code': '50SL')
                                        .last(300).sample
        expect(mprg.meeting_individual_results.count).to be_positive
        mprg.meeting_individual_results.by_rank
      end
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', MeetingIndividualResult, 'rank')
    end

    describe 'self.by_date' do
      let(:result) do
        mirs = GogglesDb::MeetingIndividualResult.where(swimmer_id: 142).by_date
        expect(mirs.count).to be > 300
        mirs
      end
      it 'is a MeetingIndividualResult relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(MeetingIndividualResult)
      end
      it 'is ordered' do
        expect(result.first.meeting_session.scheduled_date).to be <= result.sample.meeting_session.scheduled_date
        expect(result.sample.meeting_session.scheduled_date).to be <= result.last.meeting_session.scheduled_date
      end
    end

    describe 'self.by_timing' do
      let(:result) do
        mprg = GogglesDb::MeetingProgram.includes(:meeting_individual_results, :event_type)
                                        .joins(:meeting_individual_results, :event_type)
                                        .where('event_types.code': '50SL')
                                        .last(300).sample
        expect(mprg.meeting_individual_results.count).to be_positive
        # (Note: exclude disqualified results to simplify time comparison)
        mprg.meeting_individual_results.qualifications.by_timing
      end
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', MeetingIndividualResult, 'to_timing')
    end

    # TODO: FUTUREDEV
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
    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'pool_type')
    end
    describe 'self.for_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'event_type')
    end
    describe 'self.for_gender_type' do
      it_behaves_like(
        'filtering scope for_<ANY_CHOSEN_FILTER>',
        MeetingIndividualResult,
        'for_gender_type',
        'gender_type',
        GogglesDb::GenderType.send(%w[male female].sample)
      )
    end
    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'swimmer')
    end

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', MeetingIndividualResult, 'team')
    end
    describe 'self.for_rank' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', MeetingIndividualResult, 'for_rank', 'rank', (1..10).to_a.sample)
    end

    describe 'self.with_rank' do
      it_behaves_like('filtering scope with_rank', MeetingIndividualResult)
    end
    describe 'self.with_no_rank' do
      it_behaves_like('filtering scope with_no_rank', MeetingIndividualResult)
    end
    describe 'self.with_time' do
      it_behaves_like('filtering scope with_time', MeetingIndividualResult)
    end
    describe 'self.with_no_time' do
      it_behaves_like('filtering scope with_no_time', MeetingIndividualResult)
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
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      let(:fixture_mir) { MeetingIndividualResult.limit(500).sample }
      before(:each) { expect(fixture_mir).to be_a(MeetingIndividualResult).and be_valid }

      subject { fixture_mir.minimal_attributes }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      it 'includes the string timing' do
        expect(subject['timing']).to eq(fixture_mir.to_timing.to_s)
      end
      %w[swimmer team_affiliation disqualification_code_type].each do |association_name|
        it "includes the #{association_name} association key" do
          # Don't check nil association links: (it may happen)
          expect(subject.keys).to include(association_name) if fixture_mir.send(association_name).present?
        end
      end
      it "contains the 'synthetized' swimmer details" do
        expect(subject['swimmer']).to be_an(Hash).and be_present
        expect(subject['swimmer']).to eq(fixture_mir.swimmer_attributes)
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_individual_result) }

      it 'includes the string timing' do
        expect(JSON.parse(subject.to_json)['timing']).to eq(subject.to_timing.to_s)
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_program team_affiliation pool_type event_type category_type gender_type stroke_type]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting meeting_session swimmer]
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
