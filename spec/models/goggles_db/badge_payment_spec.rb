# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe BadgePayment, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:badge_payment) }

      it 'is valid' do
        expect(subject).to be_a(BadgePayment).and be_valid
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
        %i[payment_date amount
           to_json]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[payment_date amount]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_date' do
      it_behaves_like('sorting scope by_date', BadgePayment)
    end

    # Filtering scopes:
    describe 'self.for_badge' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', BadgePayment, 'badge')
    end
    describe 'self.for_badges' do
      it_behaves_like('filtering scope for_<PLURAL_ENTITY_NAME>', BadgePayment, 'badge')
    end
    describe 'self.for_swimmer' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', BadgePayment, 'swimmer')
    end
    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', BadgePayment, 'team')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_json' do
      subject { FactoryBot.create(:badge_payment) }

      it_behaves_like(
        '#to_json when called on a valid model instance with',
        %w[badge swimmer season team]
      )
    end
  end
end
