# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_db_finders_base_strategy_examples'

module GogglesDb
  RSpec.describe DbFinders::FuzzyTeam, type: :strategy do
    let(:fixture_row) { GogglesDb::Team.first(50).sample }

    describe 'any instance' do
      subject { described_class.new(editable_name: fixture_row.editable_name) }

      it_behaves_like(
        'responding to a list of methods',
        %i[matches normalize_value scan_for_matches sort_matches]
      )
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using valid parameters' do
      describe '#scan_for_matches,' do
        subject { described_class.new(editable_name: fixture_row.editable_name) }

        before { subject.scan_for_matches }

        it_behaves_like('DbFinders::BaseStrategy successful #scan_for_matches')
      end

      describe '#scan_for_matches finding a single result (1:1),' do
        [
          # 1:1 matches:
          'West Concetta Swimming Club 2022', 'Framistad Swimming Club 2021',
          'Ogaberg Swimming Club ASD'
        ].each do |fixture_value|
          describe "#call ('#{fixture_value}')" do
            subject { described_class.new(editable_name: fixture_value) }

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
          'North Gia Swimming Club', 'East Swimming Club ASD', 'Ramiro Swimming Club',
          'West', 'Lake'
        ].each do |fixture_value|
          describe "#call ('#{fixture_value}')" do
            subject { described_class.new(editable_name: fixture_value) }

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
