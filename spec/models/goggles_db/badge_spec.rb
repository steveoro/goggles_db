# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe Badge, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:badge) }

      it 'is valid' do
        expect(subject).to be_a(Badge).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season swimmer team category_type entry_time_type]
      )
      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end
      it 'has a valid CategoryType' do
        expect(subject.category_type).to be_a(CategoryType).and be_valid
      end
      it 'has a valid Swimmer' do
        expect(subject.swimmer).to be_a(Swimmer).and be_valid
      end
      it 'has a valid Team' do
        expect(subject.team).to be_a(Team).and be_valid
      end
      it 'has a valid EntryTimeType' do
        expect(subject.entry_time_type).to be_a(EntryTimeType).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[season_type gender_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[number]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_season' do
      let(:result) { subject.class.by_season }
      it 'is a Badge relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(Badge)
      end
      # Checks just the boundaries with a random middle point in between:
      it 'is ordered' do
        expect(result.first.season.begin_date).to be <= result.sample.season.begin_date
        expect(result.sample.season.begin_date).to be <= result.last.season.begin_date
      end
    end

    describe 'self.by_swimmer' do
      let(:result) { subject.class.by_swimmer }
      it 'is a Badge relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(Badge)
      end
      it 'is ordered' do
        expect(result.first.swimmer.complete_name).to be <= result.sample.swimmer.complete_name
        expect(result.sample.swimmer.complete_name).to be <= result.last.swimmer.complete_name
      end
    end

    describe 'self.by_category_type' do
      let(:result) { subject.class.by_category_type }
      it 'is a Badge relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(Badge)
      end
      it 'is ordered' do
        expect(result.first.category_type.code).to be <= result.sample.category_type.code
        expect(result.sample.category_type.code).to be <= result.last.category_type.code
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    # TODO
  end
end
