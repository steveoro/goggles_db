# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe Calculators::Factory, type: :strategy do
    let(:fixture_event) { GogglesDb::EventType.all_eventable.sample }
    let(:fixture_pool) { GogglesDb::PoolType.all_eventable.sample }

    it 'responds to self.for' do
      expect(described_class).to respond_to(:for)
    end

    describe 'self.for' do
      context 'without required parameters (badge || season + gender + category),' do
        subject { described_class.for(pool_type: fixture_pool, event_type: fixture_event) }

        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      %i[mas_fin mas_fina mas_len].each do |season_type_sym|
        let(:fixture_badge) { GogglesDb::Badge.for_season_type(GogglesDb::SeasonType.send(season_type_sym)).sample }
        let(:season_from_badge) { fixture_badge.season }
        let(:gender_from_badge) { fixture_badge.gender_type }
        let(:category_from_badge) { fixture_badge.category_type }

        context "with a '#{season_type_sym}'-type Season," do
          subject do
            described_class.for(
              pool_type: fixture_pool, event_type: fixture_event,
              season: season_from_badge, gender_type: gender_from_badge, category_type: category_from_badge
            )
          end

          it 'is a FINScore strategy' do
            expect(subject).to be_a(Calculators::FINScore)
          end
        end

        context "with a '#{season_type_sym}'-type Badge," do
          subject { described_class.for(pool_type: fixture_pool, event_type: fixture_event, badge: fixture_badge) }

          it 'is a FINScore strategy' do
            expect(subject).to be_a(Calculators::FINScore)
          end
        end
      end

      context "with a 'MAS-CSI' season type," do
        let(:csi_badge) { GogglesDb::Badge.for_season_type(GogglesDb::SeasonType.mas_csi).sample }
        let(:season_from_badge) { csi_badge.season }
        let(:gender_from_badge) { csi_badge.gender_type }
        let(:category_from_badge) { csi_badge.category_type }

        context 'with proper season options,' do
          subject do
            described_class.for(
              pool_type: fixture_pool, event_type: fixture_event,
              season: season_from_badge, gender_type: gender_from_badge, category_type: category_from_badge
            )
          end

          it 'is a CSIScore strategy' do
            expect(subject).to be_a(Calculators::CSIScore)
          end
        end

        context 'with proper badge options,' do
          subject { described_class.for(pool_type: fixture_pool, event_type: fixture_event, badge: csi_badge) }

          it 'is a CSIScore strategy' do
            expect(subject).to be_a(Calculators::CSIScore)
          end
        end
      end

      context "with a 'MAS-UISP' season type," do
        let(:uisp_badge) { GogglesDb::Badge.for_season_type(GogglesDb::SeasonType.mas_uisp).sample }
        let(:season_from_badge) { uisp_badge.season }
        let(:gender_from_badge) { uisp_badge.gender_type }
        let(:category_from_badge) { uisp_badge.category_type }

        context 'with proper season options,' do
          subject do
            described_class.for(
              pool_type: fixture_pool, event_type: fixture_event,
              season: season_from_badge, gender_type: gender_from_badge, category_type: category_from_badge
            )
          end

          it 'is a UISPScore strategy' do
            expect(subject).to be_a(Calculators::UISPScore)
          end
        end

        context 'with proper badge options,' do
          subject { described_class.for(pool_type: fixture_pool, event_type: fixture_event, badge: uisp_badge) }

          it 'is a UISPScore strategy' do
            expect(subject).to be_a(Calculators::UISPScore)
          end
        end
      end
    end
  end
end
