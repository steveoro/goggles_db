# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'
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
          ['Lake Ramiro', 37],
          ['East Minbury', 27],
          ['Kautzertown', 9]
        ].each do |fixture_value, filter_city_id|
          describe "#call ('#{fixture_value}')" do
            subject { described_class.new(editable_name: fixture_value, city_id: filter_city_id) }

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
          'Lake Ramiro',
          'East Minbury',
          'Ramiro',
          'East',
          'Lake'
        ].each do |fixture_value|
          describe "#call ('#{fixture_value}')" do
            subject { described_class.new(name: fixture_value) }

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

    # Deterministic, DB-independent tests for the multi-field scoring behavior:
    # a strong match on 'editable_name' or any ';'/','-separated 'name_variations' token must
    # not be penalized just because the main 'name' column differs.
    context 'when scoring against multiple name columns,' do
      subject { described_class.new(name: search_name) }

      let(:search_name) { 'Amatori Nuoto ssd arl' }
      # Minimal candidate stand-in responding to the three scored columns:
      let(:candidate_struct) { Struct.new(:name, :editable_name, :name_variations) }

      describe 'the declared scored/multi-value columns' do
        it 'scores against name, editable_name and name_variations' do
          expect(subject.instance_variable_get(:@score_columns)).to match_array(%i[name editable_name name_variations])
        end

        it 'treats name_variations as a multi-value column' do
          expect(subject.instance_variable_get(:@multi_value_columns)).to include(:name_variations)
        end
      end

      describe '#perfect_match?' do
        it 'is true when editable_name equals the search value (name differs)' do
          candidate = candidate_struct.new('Amatori Nuoto Soc. Coop Dilettantistica', 'Amatori Nuoto ssd arl', nil)
          expect(subject.send(:perfect_match?, candidate)).to be true
        end

        it 'is true when a ;-separated name_variations token equals the search value' do
          candidate = candidate_struct.new(
            'Amatori Nuoto Soc. Coop Dilettantistica',
            'Amatori Nuoto Soc. Coop Dilettantistica',
            'Amatori Nuoto ssd arl;Amatori Nuoto Soc. Coop Dilettantistica'
          )
          expect(subject.send(:perfect_match?, candidate)).to be true
        end

        it 'is true when a ,-separated name_variations token equals the search value' do
          candidate = candidate_struct.new('Whatever', 'Whatever', 'Foo Team,Amatori Nuoto ssd arl')
          expect(subject.send(:perfect_match?, candidate)).to be true
        end

        it 'is false when no scored column matches' do
          candidate = candidate_struct.new('Totally Different Club', 'Totally Different Club', 'Some Other Name')
          expect(subject.send(:perfect_match?, candidate)).to be false
        end
      end

      describe '#compute_best_weight' do
        # Mirrors the real-world Amatori case (ID 294 vs ID 1361):
        let(:weak_name_candidate) do
          candidate_struct.new('AMATORI NUOTO LIB', 'AMATORI NUOTO LIB', 'AMATORI NUOTO LIB')
        end
        let(:strong_alias_candidate) do
          candidate_struct.new(
            'Amatori Nuoto Soc. Coop Dilettantistica',
            'Amatori Nuoto ssd arl',
            'Amatori Nuoto ssd arl;Amatori Nuoto Soc. Coop Dilettantistica'
          )
        end

        it 'ranks the strong editable_name/name_variations candidate above the weak name-only candidate' do
          expect(subject.send(:compute_best_weight, strong_alias_candidate))
            .to be > subject.send(:compute_best_weight, weak_name_candidate)
        end

        it 'gives the strong alias candidate a weight above the match bias' do
          expect(subject.send(:compute_best_weight, strong_alias_candidate)).to be >= 0.74
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
