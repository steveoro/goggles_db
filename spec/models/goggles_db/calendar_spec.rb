# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Calendar, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:calendar) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season]
      )
      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[season meeting
           meeting_code scheduled_date meeting_name meeting_place
           year month
           manifest_code startlist_code results_code
           results_link startlist_link manifest_link
           manifest
           name_import_text organization_import_text
           place_import_text dates_import_text program_import_text
           read_only?
           to_json]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[meeting_code]
      )
    end
    #-- -----------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_date' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'date', 'scheduled_date')
    end

    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'begin_date')
    end

    # Filtering scopes:
    describe 'self.for_season_type' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season_type', 'season_type',
                      described_class.includes(:season_type).joins(:season_type).last(300).sample.season_type)
    end

    describe 'self.for_season' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season', 'season',
                      described_class.includes(:meeting, :season).joins(:meeting, :season).last(300).sample.season)
    end

    describe 'self.for_code' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_code', 'meeting_code',
                      described_class.last(300).pluck(:meeting_code).uniq.sample)
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      context 'for a row with an associated Meeting,' do
        subject { FactoryBot.create(:calendar) }

        it_behaves_like(
          '#to_json when called on a valid instance',
          %w[season]
        )
      end

      context 'for a row without an associated Meeting,' do
        subject { described_class.where(meeting_id: nil).first(300).sample }

        it_behaves_like(
          '#to_json when called with unset optional associations',
          %w[meeting]
        )
      end
    end
  end
end
