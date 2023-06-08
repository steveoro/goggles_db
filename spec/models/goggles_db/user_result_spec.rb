# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_result_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe UserResult do
    # Make sure UserResult have some permanent fixtures:
    # (These are supposed to remain there, and this is why an "after(:all)" clearing block
    # is totally missing here)
    before(:all) do
      if (GogglesDb::UserWorkshop.count < 10) || (described_class.count < 40) ||
         (GogglesDb::UserLap.count < 80)
        FactoryBot.create_list(:workshop_with_results_and_laps, 3)
        FactoryBot.create_list(:user_result_with_laps, 3, disqualified: true)
        FactoryBot.create_list(:user_result_with_laps, 5, disqualified: false)
      end
      expect(GogglesDb::UserWorkshop.count).to be_positive
      expect(described_class.count).to be_positive
      expect(GogglesDb::UserLap.count).to be_positive
    end

    shared_examples_for 'a valid UserResult instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user_workshop user swimmer swimming_pool
           pool_type event_type category_type
           gender_type stroke_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[rank standard_points meeting_points reaction_time minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[user_laps laps
           season season_type
           disqualified? valid_for_ranking? to_timing
           standard_timing meeting_attributes swimmer_attributes
           minimal_attributes to_json]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(10).sample }

      it_behaves_like('a valid UserResult instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user_result) }

      it_behaves_like('a valid UserResult instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    it_behaves_like('AbstractResult sorting scopes', described_class)

    # describe 'self.by_rank' do
    #   let(:result) { described_class.by_rank.limit(20) }

    #   it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'rank')
    # end

    describe 'self.by_date' do
      let(:result) { described_class.by_date.limit(20) }

      it 'is a UserResult relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
      end

      it 'is ordered' do
        expect(result.first.user_workshop.header_date).to be <= result.sample.user_workshop.header_date
        expect(result.sample.user_workshop.header_date).to be <= result.last.user_workshop.header_date
      end
    end

    # describe 'self.by_timing' do
    #   let(:result) { described_class.by_timing.limit(20) }

    #   it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'to_timing')
    # end

    # Filtering scopes:
    it_behaves_like('AbstractResult filtering scopes', described_class)

    describe 'self.for_workshop_code' do
      let(:workshop_filter) { UserWorkshop.all.sample }
      let(:result) { described_class.for_workshop_code(workshop_filter).limit(10) }

      it 'is a relation containing only MeetingIndividualResults associated to the filter' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
        list_of_codes = result.map { |row| row.user_workshop.code }.uniq.sort
        expect(list_of_codes).to eq([workshop_filter.code])
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#valid_for_ranking?' do
      context 'for any valid result (not disqualified)' do
        subject { fixture_row.valid_for_ranking? }

        let(:fixture_row) { FactoryBot.build(:user_result, disqualified: false) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'for any disqualified result' do
        subject { fixture_row.valid_for_ranking? }

        let(:fixture_row) { FactoryBot.build(:user_result, disqualified: true) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:user_result) }

      it_behaves_like 'TimingManageable'
    end
    #-- ------------------------------------------------------------------------
    #++

    it_behaves_like(
      'AbstractResult #minimal_attributes',
      described_class,
      %w[swimmer swimming_pool disqualification_code_type]
    )

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { FactoryBot.create(:user_result) }

      it 'includes the event label' do
        expect(result['event_label']).to eq(fixture_row.event_type.label)
      end

      it 'includes the category code & label' do
        expect(result['category_code']).to eq(fixture_row.category_type.code)
        expect(result['category_label']).to eq(fixture_row.category_type.decorate.short_label)
      end

      it 'includes the gender code' do
        expect(result['gender_code']).to eq(fixture_row.gender_type.code)
      end
    end

    describe '#to_hash' do
      subject { FactoryBot.create(:user_result) }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[swimming_pool pool_type event_type category_type gender_type stroke_type]
      )
      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[user_workshop swimmer]
      )

      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject { FactoryBot.create(:user_result_with_laps) }

        it_behaves_like(
          '#to_hash when the entity has any 1:N collection association with',
          %w[laps]
        )
      end
    end
  end
end
