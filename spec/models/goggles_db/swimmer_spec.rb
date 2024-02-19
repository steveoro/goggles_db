# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe Swimmer do
    subject(:new_swimmer) { FactoryBot.create(:swimmer) }

    let(:new_badge) { FactoryBot.create(:badge) }
    let(:swimmer_with_badge) { new_badge.swimmer }

    context 'when using the factory, the resulting instance' do
      it_behaves_like(
        'having one or more required associations',
        %i[gender_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[
          associated_user male? female? intermixed? year_guessed?
          age associated_team_ids associated_teams
          last_category_type_by_badge latest_category_type
          minimal_attributes to_json
        ]
      )

      it_behaves_like('ApplicationRecord shared interface')
      #-- ----------------------------------------------------------------------
      #++

      it 'is valid' do
        expect(new_swimmer).to be_a(described_class).and be_valid
      end

      it 'has a valid GenderType' do
        expect(new_swimmer.gender_type).to be_a(GenderType).and be_valid
      end

      it 'is does not have an associated user yet' do
        expect(new_swimmer).to respond_to(:associated_user)
        expect(new_swimmer.associated_user).to be_nil
      end

      it 'has a #complete_name' do
        expect(new_swimmer).to respond_to(:complete_name)
        expect(new_swimmer.complete_name).to be_present
      end

      it 'has a #year_of_birth' do
        expect(new_swimmer).to respond_to(:year_of_birth)
        expect(new_swimmer.year_of_birth).to be_present
      end
    end

    describe '#age' do
      context 'with no parameters,' do
        it 'returns the current age of the swimmer' do
          expect(new_swimmer.age).to eq(Time.zone.today.year - new_swimmer.year_of_birth)
        end
      end

      context 'with a given date,' do
        it 'returns the age of the swimmer during that date\'s year' do
          sample_date = Time.zone.today + ((rand * 30) - (rand * 15)).to_i.years
          expect(new_swimmer.age(sample_date)).to eq(sample_date.year - new_swimmer.year_of_birth)
        end
      end
    end

    describe '#associated_team_ids' do
      context 'with a swimmer having existing badges,' do
        let(:result) { swimmer_with_badge.associated_team_ids }

        it 'is a non-empty Array' do
          expect(result).to be_an(Array)
          expect(result.count).to be_positive
        end

        it 'contains only valid associations with Teams' do
          expect(GogglesDb::Team.where(id: result)).to all be_a(GogglesDb::Team)
        end
      end

      context 'with a swimmer having no badge,' do
        let(:result) { new_swimmer.associated_team_ids }

        it 'is an empty Array' do
          expect(result).to be_an(Array).and be_empty
        end
      end
    end

    describe '#associated_teams' do
      context 'with a swimmer having existing badges,' do
        let(:result) { swimmer_with_badge.associated_teams }

        it 'contains only Teams associated with the swimmer throught one badge or more' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(GogglesDb::Team)
          result.each do |team|
            expect(GogglesDb::Badge.exists?(swimmer_id: swimmer_with_badge.id, team_id: team.id)).to be true
          end
        end

        it 'is a non-empty relation' do
          expect(result.count).to be_positive
        end
      end

      context 'with a swimmer having no badge,' do
        let(:result) { new_swimmer.associated_teams }

        it 'is an empty relation' do
          expect(result.count).to be_zero
        end
      end
    end

    describe '#last_category_type_by_badge' do
      context 'with a swimmer having existing badges,' do
        let(:result) { swimmer_with_badge.last_category_type_by_badge }

        it 'returns a valid CategoryType' do
          expect(result).to be_a(GogglesDb::CategoryType).and be_valid
        end

        it 'corresponds to the CategoryType for the latest associated badge' do
          latest_badge = GogglesDb::Badge.for_swimmer(swimmer_with_badge)
                                         .by_season
                                         .includes(:category_type)
                                         .last
          expect(result.code).to eq(latest_badge.category_type.code)
        end
      end

      context 'with a swimmer having no badge,' do
        let(:result) { new_swimmer.last_category_type_by_badge }

        it 'returns nil' do
          expect(result).to be_nil
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#latest_category_type' do
      GogglesDb::SeasonType.all_masters.each do |fixture_season_type|
        context "with a #{fixture_season_type.code} season type," do
          # ASSUMES:
          # - fixture_season_type: SeasonType used as parameter
          # - fixture_swimmer: Swimmer instance used to compute #latest_category_type
          # - result: CategoryType resulted from #latest_category_type
          shared_examples_for '#latest_category_type for any kind of valid Swimmer' do
            it 'returns a valid CategoryType' do
              expect(result).to be_a(GogglesDb::CategoryType).and be_valid
            end

            it 'belongs to the specified SeasonType' do
              expect(result.season.season_type_id).to eq(fixture_season_type.id)
            end

            it 'is in range with the swimmer age' do
              expect(fixture_swimmer.age).to be >= result.age_begin
              expect(fixture_swimmer.age).to be <= result.age_end
            end
          end

          context 'with a swimmer having existing badges,' do
            let(:fixture_swimmer) { swimmer_with_badge }
            let(:result) { fixture_swimmer.latest_category_type(fixture_season_type) }

            it_behaves_like('#latest_category_type for any kind of valid Swimmer')
          end

          context 'with a swimmer having no badge,' do
            let(:fixture_swimmer) { new_swimmer }
            let(:result) { new_swimmer.latest_category_type(fixture_season_type) }

            it_behaves_like('#latest_category_type for any kind of valid Swimmer')
          end
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.for_name' do
      %w[john steve nicolas nicole serena].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_name, %w[last_name first_name complete_name], filter_text)
      end
    end

    describe 'self.for_first_name' do
      %w[john steve nicolas nicole serena].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_first_name, %w[first_name], filter_text)
      end
    end

    describe 'self.for_last_name' do
      %w[Alloro Jenkins Ligabue Smith].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_last_name, %w[last_name], filter_text)
      end
    end

    describe 'self.for_complete_name' do
      ['Alloro Stefano', 'Jenkins', 'Ligabue', 'Smith'].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_complete_name, %w[complete_name], filter_text)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.first(200).sample }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end

      it "includes #long_label as an alias to 'display_label'" do
        expect(result['long_label']).to eq(fixture_row.decorate.display_label)
      end

      it 'includes the gender_code' do
        expect(result['gender_code']).to eq(fixture_row.gender_type.code)
      end

      it 'includes the associated_user_label (if a user is set)' do
        expect(result['associated_user_label']).to eq(fixture_row.associated_user&.decorate&.short_label)
      end
    end

    describe '#to_hash' do
      subject { described_class.first(200).sample }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[gender_type]
      )

      # Optional associations:
      context 'when the entity contains other optional associations' do
        subject { FactoryBot.create(:swimmer, associated_user: fixture_user) }

        let(:fixture_user) { FactoryBot.create(:user) }

        it_behaves_like(
          '#to_hash when the entity has any 1:1 optional association with',
          %w[associated_user]
        )
      end
    end
  end
end
