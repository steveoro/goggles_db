# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  # REQUIRES/ASSUMES:
  # - described_class must be a kind_of Calculators::BaseStrategy
  #
  shared_examples_for 'Calculators::BaseStrategy with valid constructor paramaters' do
    # These may yield a strategy either *with* or *without an existing linked StandardTiming:
    let(:fixture_event) { GogglesDb::EventType.all_eventable.sample }
    let(:fixture_pool) { GogglesDb::PoolType.all_eventable.sample }
    let(:fixture_season_type) { GogglesDb::SeasonType.send(%i[mas_fin mas_csi mas_uisp mas_fina mas_len].sample) }
    let(:fixture_badge) { GogglesDb::Badge.for_season_type(fixture_season_type).first(2000).sample }

    # These 2 will yield a strategy *with* an existing StandardTiming:
    let(:expected_std_timing) do
      GogglesDb::StandardTiming.includes(:category_type)
                               .where('category_types.relay': false)
                               .first(5000).sample
    end

    # This will yield a strategy *without* an existing StandardTiming:
    let(:unlinked_badge) { FactoryBot.create(:badge) }

    before { expect(fixture_badge).to be_a(Badge).and be_valid }

    describe 'with valid parameters,' do
      subject do
        described_class.new(
          pool_type: fixture_pool, event_type: fixture_event,
          badge: fixture_badge, season: fixture_badge.season,
          gender_type: fixture_badge.gender_type, category_type: fixture_badge.category_type
        )
      end

      it_behaves_like('responding to a list of methods', %i[standard_timing compute_for timing_from])
      #-- ---------------------------------------------------------------------
      #++

      describe '#standard_timing' do
        before do
          expect(expected_std_timing).to be_a(StandardTiming).and be_valid
          expect(unlinked_badge).to be_a(Badge).and be_valid
        end

        context 'with an existing StandardTiming matched by the constructor parameters,' do
          subject(:result) do
            described_class.new(
              pool_type: expected_std_timing.pool_type, event_type: expected_std_timing.event_type,
              season: expected_std_timing.season,
              gender_type: expected_std_timing.gender_type,
              category_type: expected_std_timing.category_type
            ).standard_timing
          end

          it 'is the associated StandardTiming' do
            expect(result).to eq(expected_std_timing)
          end
        end

        context 'without an existing StandardTiming matched by the constructor parameters,' do
          subject(:result) do
            described_class.new(
              pool_type: fixture_pool, event_type: fixture_event,
              badge: unlinked_badge
            ).standard_timing
          end

          it 'is nil' do
            expect(result).to be nil
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      describe '#compute_for' do
        before do
          expect(expected_std_timing).to be_a(StandardTiming).and be_valid
          expect(unlinked_badge).to be_a(Badge).and be_valid
        end

        let(:max_delta) { expected_std_timing.to_timing.to_hundredths / 2 }
        let(:fixure_delta) { Timing.new.from_hundredths((1 + rand * max_delta).to_i) }

        context 'with an existing StandardTiming matched by the constructor parameters,' do
          subject(:strategy) do
            described_class.new(
              pool_type: expected_std_timing.pool_type, event_type: expected_std_timing.event_type,
              season: expected_std_timing.season,
              gender_type: expected_std_timing.gender_type,
              category_type: expected_std_timing.category_type
            )
          end

          before { expect(strategy).to be_a_kind_of(described_class) }

          context 'when the requested timing equals the existing reference,' do
            it 'returns as score of 1000' do
              expect(strategy.compute_for(expected_std_timing.to_timing).to_i).to eq(1000)
            end

            context 'with a base standard points override,' do
              it 'returns the base score override value' do
                base_score_override = (500 + rand * 400).to_i.to_f
                expect(
                  strategy.compute_for(expected_std_timing.to_timing, standard_points: base_score_override).to_i
                ).to eq(base_score_override)
              end
            end
          end

          context 'when the requested timing is above (slower than) the existing reference,' do
            let(:fixure_timing) { expected_std_timing.to_timing + fixure_delta }

            it 'returns a score < 1000' do
              expect(fixure_delta.to_hundredths).to be_positive
              expect(fixure_timing).to be > expected_std_timing.to_timing
              expect(strategy.compute_for(fixure_timing)).to be < 1000.0
            end

            context 'with a base standard points override,' do
              it 'returns a score < the base score override' do
                base_score_override = (500 + rand * 400).to_i.to_f
                expect(fixure_timing).to be > expected_std_timing.to_timing
                expect(
                  strategy.compute_for(fixure_timing, standard_points: base_score_override).to_i
                ).to be < base_score_override
              end
            end
          end

          context 'when the requested timing is under (faster than) the existing reference,' do
            let(:fixure_timing) { expected_std_timing.to_timing - fixure_delta }

            it 'returns a score > 1000' do
              expect(fixure_delta.to_hundredths).to be_positive
              expect(fixure_timing).to be < expected_std_timing.to_timing
              expect(strategy.compute_for(fixure_timing)).to be > 1000.0
            end

            context 'with a base standard points override,' do
              it 'returns a score > the base score override' do
                base_score_override = (500 + rand * 400).to_i.to_f
                expect(fixure_delta.to_hundredths).to be_positive
                expect(fixure_timing).to be < expected_std_timing.to_timing
                expect(
                  strategy.compute_for(fixure_timing, standard_points: base_score_override).to_i
                ).to be > base_score_override
              end
            end
          end
        end

        context 'without an existing StandardTiming matched by the constructor parameters,' do
          subject(:strategy) do
            described_class.new(
              pool_type: fixture_pool, event_type: fixture_event,
              badge: unlinked_badge
            )
          end

          # Any random timing shall do:
          let(:fixure_timing) { expected_std_timing.to_timing + fixure_delta * [-1, 1].sample }

          before { expect(strategy).to be_a_kind_of(described_class) }

          it 'always returns as score of 1000' do
            expect(strategy.compute_for(fixure_timing).to_i).to eq(1000)
          end

          context 'with a base standard points override,' do
            it 'always returns the base score override value' do
              base_score_override = (500 + rand * 400).to_i.to_f
              expect(
                strategy.compute_for(fixure_timing, standard_points: base_score_override).to_i
              ).to eq(base_score_override)
            end
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      describe '#timing_from' do
        before do
          expect(expected_std_timing).to be_a(StandardTiming).and be_valid
          expect(unlinked_badge).to be_a(Badge).and be_valid
        end

        context 'with an existing StandardTiming matched by the constructor parameters,' do
          subject(:strategy) do
            described_class.new(
              pool_type: expected_std_timing.pool_type, event_type: expected_std_timing.event_type,
              season: expected_std_timing.season,
              gender_type: expected_std_timing.gender_type,
              category_type: expected_std_timing.category_type
            )
          end

          before { expect(strategy).to be_a_kind_of(described_class) }

          context 'when the requested score equals the standard score,' do
            it 'is a Timing instance representing the same reference standard time' do
              result = strategy.timing_from(1000)
              expect(result).to be_a(Timing).and eq(expected_std_timing.to_timing)
            end
          end

          context 'when the requested score is < the standard score,' do
            let(:target_score) { 999 - (rand * 200).to_i }

            it 'returns a Timing instance that is longer than the reference standard time' do
              result = strategy.timing_from(target_score)
              expect(result).to be_a(Timing).and be > expected_std_timing.to_timing
            end
          end

          context 'when the requested score is > the standard score,' do
            let(:target_score) { 1001 + (rand * 100).to_i }

            it 'returns a Timing instance that is faster than the reference standard time' do
              result = strategy.timing_from(target_score)
              expect(result).to be_a(Timing).and be < expected_std_timing.to_timing
            end
          end
        end

        # Unsolvable reverse operation if the StandardTime is missing: (always zero)
        context 'without an existing StandardTiming matched by the constructor parameters,' do
          subject(:strategy) do
            described_class.new(
              pool_type: fixture_pool, event_type: fixture_event,
              badge: unlinked_badge
            )
          end

          before { expect(strategy).to be_a_kind_of(described_class) }

          context 'when the requested score equals the standard score,' do
            it 'is a zeroed Timing instance' do
              expect(strategy.timing_from(1000)).to be_a(Timing).and be_zero
            end
          end

          context 'when the requested score is < the standard score,' do
            it 'is a zeroed Timing instance' do
              expect(strategy.timing_from(999 - (rand * 200).to_i)).to be_a(Timing).and be_zero
            end
          end

          context 'when the requested score is > the standard score,' do
            it 'is a zeroed Timing instance' do
              expect(strategy.timing_from(1001 + (rand * 200).to_i)).to be_a(Timing).and be_zero
            end
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++
    end
  end
end
