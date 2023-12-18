# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe BadgePayment do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:badge_payment) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[badge swimmer season team]
      )
      it 'has a valid badge' do
        expect(subject.badge).to be_a(Badge).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[payment_date amount swimmer_complete_name
           manual?]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[payment_date amount]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_date' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'date', 'payment_date')
    end

    # Filtering scopes:
    describe 'self.for_badge' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'badge')
    end

    describe 'self.for_badges' do
      it_behaves_like('filtering scope for_<PLURAL_ENTITY_NAME>', described_class, 'badge')
    end

    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'swimmer')
    end

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_hash' do
      subject { FactoryBot.create(:badge_payment) }

      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[badge swimmer season team]
      )
    end
  end
end
