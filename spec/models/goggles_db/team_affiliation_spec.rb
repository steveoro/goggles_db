# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe TeamAffiliation do
    let(:fixture_manager) do
      manager = FactoryBot.create(:user)
      FactoryBot.create(:managed_affiliation, team_affiliation: affiliation_with_badges, manager:)
      affiliation_with_badges.reload
      manager
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:affiliation_with_badges) { FactoryBot.create(:affiliation_with_badges) }

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team_affiliation) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season team]
      )
      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end

      it 'has a valid Team' do
        expect(subject.team).to be_a(Team).and be_valid
      end

      it_behaves_like(
        'responding to a list of class methods',
        %i[for_year for_years for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[season_type badges managed_affiliations
           recent_badges managers autofilled?
           number header_year]
      )

      it_behaves_like('ApplicationRecord shared interface')

      # Presence of fields & required-ness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    # (TODO: none yet)

    # Filtering scopes:
    describe 'self.for_years' do
      it_behaves_like('filtering scope for_years', described_class)
    end

    describe 'self.for_year' do
      it_behaves_like('filtering scope for_year', described_class)
    end

    describe 'self.for_name' do
      context 'when combined with other associations that include same-named columns,' do
        subject do
          described_class.joins(:team)
                         .includes(:team)
                         .for_name(%w[ferrari dynamic reggiana].sample)
        end

        it 'does not raise errors' do
          expect { subject.count }.not_to raise_error
        end
      end

      %w[ferrari dynamic reggiana].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_name, %w[name], filter_text)
      end
    end

    describe '#recent_badges' do
      let(:result) { affiliation_with_badges.recent_badges.limit(10) }

      it 'is a relation containing only Badges belonging to the last couple of years' do
        expect(result).to be_an(ActiveRecord::Relation)
        expect(result).to all be_a(Badge)
        result.map(&:header_year).uniq.each do |header_year|
          expect(header_year).to include((Time.zone.today.year - 1).to_s).or include(Time.zone.today.year.to_s)
        end
      end
    end

    describe '#managers' do
      let(:result) { affiliation_with_badges.managers }

      it 'is a relation containing only Users that are associated to this affiliation as Team managers' do
        # Force fixture_manager to be created before testing the result:
        expect(fixture_manager).to be_a(User)
        expect(result).to be_an(Array)
        expect(result).not_to be_empty
        expect(result).to all be_a(User)
        expect(result).to include(fixture_manager)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.first(100).sample }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end
    end

    describe '#to_hash' do
      # Make sure both collection association are present by making an educated guess:
      subject { GogglesDb::ManagedAffiliation.first(20).sample.team_affiliation }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[team season]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        it_behaves_like(
          '#to_hash when the entity has any 1:N collection association with',
          %w[badges managed_affiliations]
        )
      end
    end
  end
end
