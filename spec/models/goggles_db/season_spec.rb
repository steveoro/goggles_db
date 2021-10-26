# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Season, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:season) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
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
        'responding to a list of class methods',
        %i[for_season_type ongoing ended ended_before]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[meetings meeting_team_scores computed_season_rankings standard_timings
           category_types badges swimmers team_affiliations teams
           ended? started? ongoing? individual_rank?]
      )
      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[header_year edition description begin_date end_date]
      )
      #-- ----------------------------------------------------------------------
      #++

      describe 'self.last_season_by_type' do
        GogglesDb::SeasonType.all_masters.each do |fixture_season_type|
          context "with a #{fixture_season_type.code} season type," do
            let(:result) { described_class.last_season_by_type(fixture_season_type) }

            it 'returns a valid Season' do
              expect(result).to be_a(described_class).and be_valid
            end

            it 'belongs to the specified SeasonType' do
              expect(result.season_type_id).to eq(fixture_season_type.id)
            end
          end
        end
      end
      #-- ----------------------------------------------------------------------
      #++

      shared_examples_for 'Season date range checking methods evaluating a custom date' do |method_name, member_name|
        context 'when checking specific dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            expect(subject.send(method_name, subject.end_date + 365.days)).to be true
            expect(subject.send(method_name, subject.end_date - 365.days)).to be false
          end
        end

        context 'when the subject has invalid dates,' do
          it 'returns always false' do
            subject.send(member_name, nil)
            expect(subject.send(method_name, Date.parse('2025-12-31'))).to be false
            expect(subject.send(method_name, Date.parse('1999-01-01'))).to be false
            expect(subject.send(method_name)).to be false
          end
        end
      end

      describe '#ended?' do
        it_behaves_like('Season date range checking methods evaluating a custom date', :ended?, :end_date=)

        context 'when moving or extending the subject dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            subject.begin_date = Time.zone.today - 465.days
            subject.end_date = Time.zone.today - 100.days
            expect(subject.ended?).to be true

            subject.begin_date = Time.zone.today - 265.days
            subject.end_date = Time.zone.today + 100.days
            expect(subject.ended?).to be false
          end
        end
      end

      describe '#started?' do
        it_behaves_like('Season date range checking methods evaluating a custom date', :started?, :begin_date=)

        context 'when moving or extending the subject dates,' do
          it 'evaluates the given date returning true or false accordingly' do
            subject.begin_date = Time.zone.today - 200.days
            expect(subject.started?).to be true

            subject.begin_date = Time.zone.today + 100.days
            expect(subject.started?).to be false
          end
        end
      end

      describe '#ongoing?' do
        context 'when checking dates outside the season definition,' do
          it 'is always false' do
            expect(subject.ongoing?(subject.begin_date + 365.days)).to be false
            expect(subject.ongoing?(subject.begin_date - 365.days)).to be false
          end
        end

        context 'when checking dates inside the season definition,' do
          it 'is always true' do
            expect(subject.ongoing?).to be true # (Default seasons created by the factory will always be ongoing)
          end
        end

        context 'when checking a not-yet started season,' do
          it 'is always false' do
            subject.begin_date = Time.zone.today + 1.month
            expect(subject.ongoing?).to be false
          end
        end

        context 'when checking an already ended season,' do
          it 'is always false' do
            subject.end_date = Time.zone.today - 1.week
            expect(subject.ongoing?).to be false
          end
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Scopes & "virtual" scopes:
    describe 'self.for_season_type' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season_type', 'season_type', GogglesDb::SeasonType.all_masters.sample)
    end

    describe 'self.ongoing' do
      context 'given existing ongoing Seasons,' do
        # The subject instance created with the factory is assumed to be ongoing by default,
        # so the result shall never be an empty relation
        let(:result) { subject.class.ongoing }

        it 'is a list of started, ongoing Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class).and be_ongoing
          expect(result).to all be_a(described_class).and be_started
          expect(result.none?(&:ended?)).to be true
        end
      end
    end

    describe 'self.ended' do
      context 'given existing ended Seasons,' do
        let(:result) { subject.class.ended }

        it 'is a list of started, ended Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class).and be_ended
        end
      end
    end

    describe 'self.ended_before' do
      context 'given existing Seasons ended before the limit date,' do
        let(:limit_date) { subject.class.ended.sample.end_date }
        let(:result)     { subject.class.ended_before(limit_date) }

        it 'returns a list of started, ended Seasons' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class).and be_ended
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
          expect(result).to all be_a(described_class)
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

    describe 'self.last_season_by_type' do
      GogglesDb::SeasonType.all_masters.each do |season_type|
        context "for a valid SeasonType '#{season_type.code}' for which exists at least a Season," do
          subject { described_class.last_season_by_type(season_type) }

          it 'returns a valid instance of Season' do
            expect(subject).to be_a(described_class).and be_valid
          end
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      subject { FactoryBot.create(:season) }

      # Required keys:
      %w[
        display_label short_label
        season_type edition_type timing_type category_types
      ].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(subject.to_json[member_name]).to be_present
        end
      end

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[season_type edition_type timing_type]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject do
          category = GogglesDb::CategoryType.joins(:season).limit(300).sample
          expect(category.season).to be_a(described_class).and be_valid
          category.season
        end

        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[category_types]
        )
      end
    end
  end
end
