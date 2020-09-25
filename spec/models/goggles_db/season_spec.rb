# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe Season, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:season) }

      it 'is valid' do
        expect(subject).to be_a(Season).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season_type edition_type timing_type federation_type]
      )
      it 'has a valid SeasonType' do
        expect(subject.season_type).to be_a(SeasonType).and be_valid
      end
      it 'has a valid EditionType' do
        expect(subject.edition_type).to be_a(EditionType).and be_valid
      end
      it 'has a valid TimingType' do
        expect(subject.timing_type).to be_a(TimingType).and be_valid
      end
      it 'has a valid FederationType' do
        expect(subject.federation_type).to be_a(FederationType).and be_valid
      end

      it_behaves_like(
        'having a list of scopes with no parameters',
        %i[by_begin_date by_end_date ongoing ended]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[category_types ended? started?]
      )
      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[header_year edition description begin_date end_date]
      )
      #-- ----------------------------------------------------------------------
      #++

      describe '#ended?' do
        context 'when checking specific dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            expect(subject.ended?(subject.end_date + 365.days)).to be true
            expect(subject.ended?(subject.end_date - 365.days)).to be false
          end
        end
        context 'when moving or extending the subject dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            subject.begin_date = Date.today - 465.days
            subject.end_date = Date.today - 100.days
            expect(subject.ended?).to be true

            subject.begin_date = Date.today - 265.days
            subject.end_date = Date.today + 100.days
            expect(subject.ended?).to be false
          end
        end
        context 'when the subject has invalid dates,' do
          it 'returns always false' do
            subject.end_date = nil
            expect(subject.ended?(Date.parse('2025-12-31'))).to be false
            expect(subject.ended?(Date.parse('1999-01-01'))).to be false
            expect(subject.ended?).to be false
          end
        end
      end

      describe '#started?' do
        context 'when checking specific dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            expect(subject.started?(subject.begin_date + 365.days)).to be true
            expect(subject.started?(subject.begin_date - 365.days)).to be false
          end
        end
        context 'when moving or extending the subject dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            subject.begin_date = Date.today - 200.days
            expect(subject.started?).to be true

            subject.begin_date = Date.today + 100.days
            expect(subject.started?).to be false
          end
        end
        context 'when the subject has invalid dates,' do
          it 'returns always false' do
            subject.begin_date = nil
            expect(subject.started?(Date.parse('2025-12-31'))).to be false
            expect(subject.started?(Date.parse('1999-01-01'))).to be false
            expect(subject.started?).to be false
          end
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Scopes & "virtual" scopes:
    describe 'self.for_season_type' do
      it_behaves_like('filtering scope for_season_type', Season)
    end

    describe 'self.ongoing' do
      context 'given existing ongoing Seasons,' do
        # The subject instance created with the factory is assumed to be ongoing by default,
        # so the result shall never be an empty relation
        let(:result) { subject.class.ongoing }
        it 'is a list of started, ongoing Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(Season).and be_started
          expect(result.none?(&:ended?)).to be true
        end
      end
    end

    describe 'self.ended' do
      context 'given existing ended Seasons,' do
        let(:result) { subject.class.ended }
        it 'is a list of started, ended Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(Season).and be_ended
        end
      end
    end

    describe 'self.ended_before' do
      context 'given existing Seasons ended before the limit date,' do
        let(:limit_date) { subject.class.ended.sample.end_date }
        let(:result)     { subject.class.ended_before(limit_date) }
        it 'returns a list of started, ended Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(Season).and be_ended
        end
        it 'is an actual subset of the overall ended Seasons' do
          expect(result.count).to be < subject.class.ended.count
        end
      end
      context 'when there are no existing Seasons ended before the limit date,' do
        let(:limit_date) { subject.class.ended.by_end_date.first.end_date - 1.month }
        let(:result)     { subject.class.ended_before(limit_date) }
        it 'returns an empty relation' do
          expect(result).to be_a(ActiveRecord::Relation).and be_empty
        end
      end
    end

    describe 'self.in_range' do
      context 'when there are Seasons existing within date range,' do
        let(:from_date) { subject.class.by_begin_date.sample.begin_date - 1.month }
        let(:to_date)   { from_date + 1.year }
        let(:result)    { subject.class.in_range(from_date, to_date) }
        it 'returns a list of existing Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(Season)
        end
        it 'is an actual subset of the overall ended Seasons' do
          expect(result.count).to be < subject.class.count
        end
      end
      context 'when there are no existing Seasons within date range,' do
        let(:from_date) { subject.class.by_begin_date.first.begin_date - 1.year }
        let(:to_date)   { from_date + 1.month }
        let(:result)    { subject.class.in_range(from_date, to_date) }
        it 'returns an empty relation' do
          expect(result).to be_a(ActiveRecord::Relation).and be_empty
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
