# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'
require 'support/shared_db_finders_base_strategy_examples'

module GogglesDb
  RSpec.describe DbFinders::FuzzyMeeting, type: :strategy do
    let(:fixture_row) { GogglesDb::Meeting.first(200).sample }

    describe 'any instance' do
      subject { described_class.new(description: fixture_row.description) }

      it_behaves_like(
        'responding to a list of methods',
        %i[matches normalize_value scan_for_matches sort_matches]
      )
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using valid parameters' do
      describe '#scan_for_matches,' do
        subject { described_class.new(description: fixture_row.description) }

        before { subject.scan_for_matches }

        it_behaves_like('DbFinders::BaseStrategy successful #scan_for_matches')
      end

      describe '#scan_for_matches finding a single result (1:1),' do
        [
          # 1:1 matches:
          { code: 'riccione', header_year: '2017/2018' },
          { code: 'csiprova5' }, # first come, first served => loop halts as soon as the perfect match is found
          { code: 'csiprova3', header_year: '2017/2018' },
          { code: 'bolognanuovo', header_year: '2006' }
        ].each do |fixture_row|
          describe "#call ('#{fixture_row.inspect}')" do
            subject { described_class.new(fixture_row) }

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
          { description: 'finale regionale CSI' },
          { code: 'riccione' }, { code: 'bolognanuovonuoto' }
        ].each do |fixture_row|
          describe "#call ('#{fixture_row.inspect}')" do
            subject { described_class.new(fixture_row) }

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
