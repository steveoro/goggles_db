# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'
require 'support/shared_db_finders_base_strategy_examples'

module GogglesDb
  RSpec.describe DbFinders::BaseStrategy, type: :strategy do
    let(:fixture_model) { [GogglesDb::City, GogglesDb::Team, GogglesDb::SwimmingPool].sample }
    let(:fixture_row) { fixture_model.first(100).sample }

    describe 'any instance' do
      subject { described_class.new(fixture_model, name: fixture_row.name) }

      it_behaves_like(
        'responding to a list of methods',
        %i[matches normalize_value scan_for_matches sort_matches]
      )
    end

    context 'when using valid parameters' do
      describe '#scan_for_matches,' do
        subject { described_class.new(fixture_model, name: fixture_row.name) }

        before { subject.scan_for_matches }

        it_behaves_like('DbFinders::BaseStrategy successful #scan_for_matches')
      end
    end

    context 'when using invalid parameters,' do
      it_behaves_like 'DbFinders::BaseStrategy with invalid parameters'
    end

    # Ensures the base (non-opted-in) behavior is unchanged: only the target column is scored.
    context 'with default (single-column) scoring,' do
      subject { described_class.new(GogglesDb::Team, name: 'Amatori Nuoto ssd arl') }

      let(:candidate) { Struct.new(:name, :editable_name, :name_variations).new('Totally Different', 'Amatori Nuoto ssd arl', nil) }

      it 'declares only the target column as scored' do
        expect(subject.instance_variable_get(:@score_columns)).to eq([:name])
      end

      it 'has no multi-value columns' do
        expect(subject.instance_variable_get(:@multi_value_columns)).to be_empty
      end

      it 'does not treat an editable_name-only match as a perfect match' do
        expect(subject.send(:perfect_match?, candidate)).to be false
      end
    end
  end
end
