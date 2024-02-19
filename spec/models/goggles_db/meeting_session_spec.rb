# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'

module GogglesDb
  RSpec.describe MeetingSession do
    shared_examples_for 'a valid MeetingSession instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting season season_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[meeting_events event_types meeting_programs meeting_entries]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[session_order scheduled_date description]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[swimming_pool day_part_type pool_type
           warm_up_time begin_time notes autofilled?]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    subject { described_class.joins(:meeting_events).first(100).sample }

    context 'any pre-seeded instance' do
      it_behaves_like('a valid MeetingSession instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_session) }

      it_behaves_like('a valid MeetingSession instance')
    end

    # Sorting scopes:
    describe 'self.by_order' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'order', 'session_order')
    end

    describe 'self.by_date' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'date', 'scheduled_date')
    end

    describe 'self.by_meeting' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'meeting', 'description')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_hash' do
      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[season season_type]
      )
      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[meeting]
      )

      # Collection associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:N collection association with',
        %w[meeting_events]
      )

      # Optional associations:
      context 'when the entity contains other optional associations' do
        it_behaves_like(
          '#to_hash when the entity has any 1:1 optional association with',
          %w[swimming_pool pool_type day_part_type]
        )
      end
    end
  end
end
