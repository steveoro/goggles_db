# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe Team do
    shared_examples_for 'a valid Team instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name editable_name]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[by_name for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[city badges swimmers team_affiliations seasons season_types managed_affiliations
           recent_badges recent_affiliations
           address phone_mobile phone_number fax_number e_mail contact_name
           home_page_url]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    #-- ------------------------------------------------------------------------
    #++

    let(:team_with_badges) { FactoryBot.create(:team_with_badges) }

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid Team instance')

      # Tests the validity of the default_scope based on an optional association:
      it 'does not raise errors when selecting a random row with a field name' do
        field_name = %w[name editable_name address name_variations].sample
        expect { described_class.select(field_name).limit(100).sample }.not_to raise_error
      end
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team) }

      it_behaves_like('a valid Team instance')
    end

    context 'without an associated City' do
      subject { FactoryBot.create(:team, city: nil) }

      it_behaves_like('a valid Team instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_name' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'name', 'name')
    end

    # Filtering scopes:
    describe 'self.for_name' do
      %w[ferrari dynamic reggiana].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_name, %w[name editable_name name_variations], filter_text)
      end
    end

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

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { FactoryBot.create(:team, city: GogglesDb::City.limit(20).sample) }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end

      it 'includes the associated, decorated City display label' do
        expect(result['city_name']).to eq(fixture_row.city.decorate.display_label)
      end
    end

    describe '#to_hash' do
      # Optional associations:
      context 'when the entity contains other optional associations,' do
        subject { FactoryBot.create(:team, city: GogglesDb::City.limit(20).sample) }

        it_behaves_like(
          '#to_hash when the entity has any 1:1 optional association with',
          %w[city]
        )
      end

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject { team_with_badges }

        it_behaves_like(
          '#to_hash when the entity has any 1:N collection association with',
          %w[team_affiliations]
        )
      end
    end
  end
end
