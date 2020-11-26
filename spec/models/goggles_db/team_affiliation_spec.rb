# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe TeamAffiliation, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team_affiliation) }

      it 'is valid' do
        expect(subject).to be_a(TeamAffiliation).and be_valid
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
        'responding to a list of methods',
        %i[season_type badges
           recent_badges autofilled?
           number header_year]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    # TODO

    # Filtering scopes:
    describe 'self.for_years' do
      it_behaves_like('filtering scope for_years', TeamAffiliation)
    end
    describe 'self.for_year' do
      it_behaves_like('filtering scope for_year', TeamAffiliation)
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:affiliation_with_badges) { FactoryBot.create(:affiliation_with_badges) }

    describe '#recent_badges' do
      let(:result) { affiliation_with_badges.recent_badges.limit(10) }

      it 'is a relation containing only Badges belonging to the last couple of years' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(Badge)
        result.map(&:header_year).uniq.each do |header_year|
          expect(header_year).to include((Time.zone.today.year - 1).to_s).or include(Time.zone.today.year.to_s)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      subject { FactoryBot.create(:team_affiliation) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[team season]
      )
      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject         { affiliation_with_badges }
        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[badges]
        )
      end
    end
  end
end
