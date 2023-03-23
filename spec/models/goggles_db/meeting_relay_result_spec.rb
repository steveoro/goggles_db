# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingRelayResult do
    shared_examples_for 'a valid MeetingRelayResult instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting meeting_session meeting_event meeting_program
           season_type pool_type event_type category_type gender_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[rank standard_points meeting_points reaction_time]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[minutes seconds hundredths
           entry_minutes entry_seconds entry_hundredths
           out_of_race? disqualified? valid_for_ranking?
           to_timing to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid MeetingRelayResult instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_relay_result) }

      it_behaves_like('a valid MeetingRelayResult instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_rank' do
      let(:fixture_program) do
        # Prepare 3 coherent fixtures that can be sorted consistently by both scoring
        # *and* ranking (ranking is assigned on scoring; scoring is assigned usually by timing):
        mrr = FactoryBot.create(:meeting_relay_result, rank: 1)
        FactoryBot.create(
          :meeting_relay_result,
          meeting_program: mrr.meeting_program,
          standard_points: mrr.standard_points - 100,
          meeting_points: mrr.meeting_points - 100,
          rank: 2
        )
        FactoryBot.create(
          :meeting_relay_result,
          meeting_program: mrr.meeting_program,
          standard_points: mrr.standard_points - 200,
          meeting_points: mrr.meeting_points - 200,
          rank: 3
        )
        mrr.meeting_program
      end
      let(:result) { described_class.where(meeting_program: fixture_program).by_rank }

      it 'is a MeetingRelayResult relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
      end

      it 'is ordered' do
        expect(result.first.rank).to be <= result.sample.rank
        expect(result.sample.rank).to be <= result.last.rank
      end
    end

    describe 'self.by_timing' do
      let(:result) do
        event_code = %w[S4X50SL S4X50MI S4X100SL].sample # choose one among the most common relays
        mprg = GogglesDb::MeetingProgram.includes(:event_type, :stroke_type, :meeting_relay_results)
                                        .joins(:event_type, :stroke_type, :meeting_relay_results)
                                        .where('event_types.code': event_code)
                                        .where('meeting_relay_results.disqualified != true')
                                        .first(500).sample
        expect(mprg.meeting_relay_results.count).to be_positive
        # (Note: exclude disqualified results to simplify time comparison)
        mprg.meeting_relay_results.qualifications.by_timing
      end

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'to_timing')
    end

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

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end

    describe 'self.for_rank' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_rank', 'rank', (1..10).to_a.sample)
    end

    describe 'self.with_rank' do
      it_behaves_like('filtering scope with_rank', described_class)
    end

    describe 'self.with_no_rank' do
      it_behaves_like('filtering scope with_no_rank', described_class)
    end

    describe 'self.with_time' do
      it_behaves_like('filtering scope with_time', described_class)
    end

    describe 'self.with_no_time' do
      it_behaves_like('filtering scope with_no_time', described_class)
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#valid_for_ranking?' do
      context 'for any MRR concurring in-race and not disqualified' do
        subject { mrr_fixture.valid_for_ranking? }

        let(:mrr_fixture) { FactoryBot.build(:meeting_relay_result, out_of_race: false, disqualified: false) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'for any MRR either off-race or disqualified' do
        subject { mrr_fixture.valid_for_ranking? }

        let(:mrr_fixture) { FactoryBot.build(:meeting_relay_result, out_of_race: true, disqualified: [false, true].sample) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:meeting_relay_result) }

      it_behaves_like 'TimingManageable'
    end

    describe '#minimal_attributes' do
      subject { fixture_row.minimal_attributes }

      let(:fixture_row) { FactoryBot.build(:meeting_relay_result) }

      before { expect(fixture_row).to be_a(described_class).and be_valid }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      it 'includes the timing string' do
        expect(subject['timing']).to eq(fixture_row.to_timing.to_s)
      end

      %w[team_affiliation meeting_relay_swimmers disqualification_code_type].each do |association_name|
        it "includes the #{association_name} association key" do
          # Don't check nil association links: (it may happen)
          expect(subject.keys).to include(association_name) if fixture_row.send(association_name).present?
        end
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_relay_result) }

      it 'includes the timing string' do
        expect(JSON.parse(subject.to_json)['timing']).to eq(subject.to_timing.to_s)
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_program pool_type event_type category_type gender_type]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting meeting_session]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject         { FactoryBot.create(:meeting_relay_result_with_swimmers) }

        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[meeting_relay_swimmers]
        )
      end
    end
  end
end
