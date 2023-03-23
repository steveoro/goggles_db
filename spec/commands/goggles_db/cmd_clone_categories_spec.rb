# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdCloneCategories, type: :command do
    let(:src_season) { GogglesDb::CategoryType.includes(:season).where('season_id > 0').last(200).sample.season }
    let(:dest_season) { FactoryBot.create(:season) }
    let(:src_categories) { src_season.category_types }

    before do
      expect(src_season).to be_a(GogglesDb::Season).and be_valid
      expect(dest_season).to be_a(GogglesDb::Season).and be_valid
      expect(src_categories.count).to be_positive
    end

    context 'when using valid parameters,' do
      describe '#call' do
        subject { described_class.call(src_season, dest_season) }

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'is successful' do
          expect(subject).to be_successful
        end

        it 'has a blank #errors list' do
          expect(subject.errors).to be_blank
        end

        it 'returns the list of created CategoryTypes as #result' do
          expect(subject.result).to respond_to(:each).and respond_to(:all)
          expect(subject.result).to all be_a(GogglesDb::CategoryType).and be_valid
        end

        it 'creates the same number of CategoryTypes as the source Season' do
          expect(subject.result.count).to eq(src_categories.count)
        end

        it 'assigns all the created CategoryTypes to the destination Season' do
          parent_ids = subject.result.map(&:season_id).uniq
          expect(parent_ids.count).to eq(1)
          expect(parent_ids.first).to eq(dest_season.id)
        end

        it 'creates the same number & types of category types' do
          expect(src_categories.map(&:code).sort).to match_array(subject.result.map(&:code).sort)
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid constructor parameters,' do
      describe '#call' do
        subject do
          option = [src_season, dest_season]
          # Make a random item invalid for the constructor:
          option[(rand * 10 % 2).to_i] = ''
          described_class.call(option[0], option[1])
        end

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a non-empty #errors list displaying a error message about constructor parameters' do
          expect(subject.errors).to be_present
          expect(subject.errors[:msg]).to eq(['Invalid constructor parameters'])
        end

        it 'has a nil #result' do
          expect(subject.result).to be_nil
        end
      end
    end
  end
end
