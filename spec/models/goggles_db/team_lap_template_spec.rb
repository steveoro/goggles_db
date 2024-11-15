# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe TeamLapTemplate do
    shared_examples_for 'a valid TeamLapTemplate instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[team pool_type event_type stroke_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[default_lap_lengths_for
           by_length for_team for_event_type for_pool_type templates_for]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.limit(20).sample }

      it_behaves_like('a valid TeamLapTemplate instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team_lap_template) }

      it_behaves_like('a valid TeamLapTemplate instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_length' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'length', 'length_in_meters')
    end

    # Filtering scopes:
    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end

    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'pool_type')
    end

    describe 'self.by_event_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'event_type')
    end

    describe 'self.templates_for' do
      let(:sample_length) { [100, 200, 400, 800].sample }
      # Retrieve & use existing test fixtures to guarantee result existence:
      let(:fixture_template) { described_class.where(length_in_meters: sample_length).to_a.sample }
      let(:fixture_team) { fixture_template.team }
      let(:fixture_pool) { fixture_template.pool_type }
      let(:fixture_event) { fixture_template.event_type }
      let(:result) { described_class.templates_for(fixture_team, fixture_pool, fixture_event).limit(20) }

      it 'is a TeamLapTemplate relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
      end

      it 'is ordered' do
        expect(result.first.length_in_meters).to be <= result.sample.length_in_meters
        expect(result.sample.length_in_meters).to be <= result.last.length_in_meters
      end

      it 'includes the length from the existing fixture' do
        expect(result.map(&:length_in_meters)).to include(sample_length)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.default_lap_lengths_for' do
      subject { described_class.default_lap_lengths_for(sample_tot_length, sample_pool_length) }

      let(:sample_tot_length) { [100, 200, 400, 800].sample }
      let(:sample_pool_length) { [25, 50].sample }

      it 'is an Array of positive lengths' do
        expect(subject).to be_an(Array)
        expect(subject.count).to be_positive
        expect(subject).to all(be_positive)
      end
      # Check ordering with just a random sample in the middle:

      it 'is ordered' do
        expect(subject.first).to be <= subject.sample
        expect(subject.sample).to be <= subject.last
      end
    end
  end
end
