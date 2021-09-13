# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingSession, type: :model do
    #-- ------------------------------------------------------------------------
    #++

    subject { FactoryBot.create(:meeting_session) }

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

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[session_order scheduled_date description]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[swimming_pool day_part_type pool_type
           warm_up_time begin_time notes autofilled?
           meeting_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

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

    describe '#to_json' do
      # Test a minimalistic instance first:
      subject { FactoryBot.create(:meeting_session, swimming_pool: nil, day_part_type: nil) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[season season_type]
      )
      it_behaves_like(
        '#to_json when called with unset optional associations',
        %w[swimming_pool pool_type day_part_type]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting]
      )

      # Optional associations:
      context 'when the entity contains other optional associations' do
        subject { FactoryBot.create(:meeting_session) }

        let(:json_hash) do
          expect(subject.swimming_pool).to be_a(SwimmingPool).and be_valid
          expect(subject.pool_type).to be_a(PoolType).and be_valid
          expect(subject.day_part_type).to be_a(DayPartType).and be_valid
          JSON.parse(subject.to_json)
        end

        it_behaves_like(
          '#to_json when the entity contains other optional associations with',
          %w[swimming_pool pool_type day_part_type]
        )
      end
    end
  end
end
