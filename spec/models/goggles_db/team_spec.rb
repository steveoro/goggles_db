# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Team, type: :model do
    shared_examples_for 'a valid Team instance' do
      it 'is valid' do
        expect(subject).to be_a(Team).and be_valid
      end

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name editable_name]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[city badges swimmers team_affiliations seasons season_types
           recent_badges recent_affiliations
           address phone_mobile phone_number fax_number e_mail contact_name
           home_page_url]
      )
    end

    context 'any pre-seeded instance' do
      subject { Team.all.limit(20).sample }
      it_behaves_like('a valid Team instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team) }
      it_behaves_like('a valid Team instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_name' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', Team, 'name', 'name')
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:team_with_badges) { FactoryBot.create(:team_with_badges) }

    describe '#recent_badges' do
      let(:result) { team_with_badges.recent_badges.limit(10) }

      it 'is a relation containing only Badges belonging to the last couple of years' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(Badge)
        result.map(&:header_year).uniq.each do |header_year|
          expect(header_year).to include((Time.zone.today.year - 1).to_s).or include(Time.zone.today.year.to_s)
        end
      end
    end

    describe '#recent_affiliations' do
      let(:result) { team_with_badges.recent_affiliations.limit(10) }

      it 'is a relation containing only TeamAffiliations belonging to the last couple of years' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(TeamAffiliation)
        result.map(&:header_year).uniq.each do |header_year|
          expect(header_year).to include((Time.zone.today.year - 1).to_s).or include(Time.zone.today.year.to_s)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      subject { FactoryBot.create(:team) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid model instance with',
        []
      )
      # Optional associations:
      context 'when the entity contains other optional associations,' do
        let(:json_hash) do
          expect(subject.city).to be_a(City).and be_valid
          JSON.parse(subject.to_json)
        end

        it_behaves_like(
          '#to_json when the entity contains other optional associations with',
          %w[city]
        )
      end
      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject         { team_with_badges }
        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[badges team_affiliations]
        )
      end
    end
  end
end
