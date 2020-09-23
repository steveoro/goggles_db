# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe CategoryType, type: :model do
    shared_examples_for 'a valid CategoryType instance' do
      it 'is valid' do
        expect(subject).to be_a(CategoryType).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season season_type federation_type]
      )
      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end
      it 'has a valid SeasonType' do
        expect(subject.season_type).to be_a(SeasonType).and be_valid
      end
      it 'has a valid FederationType' do
        expect(subject.federation_type).to be_a(FederationType).and be_valid
      end

      it_behaves_like(
        'having a list of scopes with no parameters',
        %i[by_age eventable
           only_relays only_individuals only_undivided only_gender_split]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[code federation_code description short_name group_name age_begin age_end
           eventable?]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[code]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:category_type) }
      it_behaves_like 'a valid CategoryType instance'
    end

    context 'any pre-seeded instance' do
      subject { CategoryType.all.sample }
      it_behaves_like 'a valid CategoryType instance'
    end
    #-- ------------------------------------------------------------------------
    #++

    # Scopes:
    describe 'self.eventable' do
      let(:result) { subject.class.eventable }
      it 'is a relation containing only non-out-of-race (eventable) category types' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all(be_eventable)
      end
    end

    describe 'self.only_relays' do
      let(:result) { subject.class.only_relays }
      it 'is a relation containing only relay category types' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all(be_relay)
      end
    end

    describe 'self.only_individuals' do
      let(:result) { subject.class.only_individuals }
      it 'is a relation containing only category types for individual events' do
        expect(result).to be_a(ActiveRecord::Relation)
        result.each do |row|
          expect(row.relay?).to be false
        end
      end
    end

    describe 'self.only_undivided' do
      let(:result) { subject.class.only_undivided }
      it 'is a relation containing only category types not divided by gender' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all(be_undivided)
      end
    end

    describe 'self.only_gender_split' do
      let(:result) { subject.class.only_gender_split }
      it 'is a relation containing only category types which are gender-split in each event' do
        expect(result).to be_a(ActiveRecord::Relation)
        result.each do |row|
          expect(row.undivided?).to be false
        end
      end
    end

    describe 'self.for_season_type' do
      context 'given the chosen SeasonType has any categories defined for it,' do
        let(:chosen_season_type) { SeasonType.only_masters.sample }
        let(:result) { subject.class.for_season_type(chosen_season_type) }
        it 'is a relation containing only category types belonging to the specified season type' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(CategoryType)
          expect(result.map(&:season_type).uniq).to all eq(chosen_season_type)
        end
      end
    end

    describe 'self.for_season' do
      context 'given the chosen Season has any categories defined for it,' do
        let(:chosen_season) do
          # Find a Season containing Categories for sure, by starting from the Categories themselves:
          row = CategoryType.includes(:season).joins(:season).select(:season_id).distinct.sample.season
          expect(row.category_types.count).to be_positive
          row
        end
        let(:result) { subject.class.for_season(chosen_season) }
        it 'is a relation containing only category types belonging to the specified season' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(CategoryType)
          expect(result.map(&:season_id).uniq).to all eq(chosen_season.id)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
