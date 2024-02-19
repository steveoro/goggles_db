# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'
require 'support/shared_db_finders_base_strategy_examples'

module GogglesDb
  RSpec.describe DbFinders::FuzzySwimmer, type: :strategy do
    let(:fixture_row) { GogglesDb::Swimmer.first(150).sample }

    describe 'any instance' do
      subject { described_class.new(complete_name: fixture_row.complete_name) }

      it_behaves_like(
        'responding to a list of methods',
        %i[matches normalize_value scan_for_matches sort_matches]
      )
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using valid parameters' do
      describe '#scan_for_matches,' do
        subject { described_class.new(complete_name: fixture_row.complete_name) }

        before { subject.scan_for_matches }

        it_behaves_like('DbFinders::BaseStrategy successful #scan_for_matches')
      end

      describe '#scan_for_matches finding a single result (1:1),' do
        [
          # 1:1 matches:
          'Alloro Stefano', 'Ligabue'
        ].each do |fixture_value|
          describe "#call ('#{fixture_value}')" do
            subject { described_class.new(complete_name: fixture_value) }

            before { subject.scan_for_matches }

            it_behaves_like('DbFinders::BaseStrategy successful #scan_for_matches')

            it 'has a single-item #matches list' do
              expect(subject.matches.count).to eq(1)
            end
          end
        end
      end

      describe '#scan_for_matches finding multiple results (1:N),' do
        [
          # 1:N matches:
          'White Sha', 'Farrell Sha'
        ].each do |fixture_value|
          describe "#call ('#{fixture_value}')" do
            subject { described_class.new(complete_name: fixture_value) }

            before { subject.scan_for_matches }

            it_behaves_like('DbFinders::BaseStrategy successful #scan_for_matches')

            it 'has possibly multiple #matches' do
              expect(subject.matches.count).to be >= 1
            end
          end
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid parameters,' do
      it_behaves_like 'DbFinders::BaseStrategy with invalid parameters'
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
