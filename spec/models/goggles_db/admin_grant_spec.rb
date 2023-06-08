# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe AdminGrant do
    shared_examples_for 'a valid AdminGrant instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[entity]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.sample }

      it_behaves_like('a valid AdminGrant instance')

      it 'has at least 2 predefined admins, with user ID 1 & 2' do
        expect(described_class.exists?(user_id: 1)).to be true
        expect(described_class.exists?(user_id: 2)).to be true
      end
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:admin_grant) }

      it_behaves_like('a valid AdminGrant instance')
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
