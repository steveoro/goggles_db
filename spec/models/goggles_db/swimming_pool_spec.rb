# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe SwimmingPool, type: :model do
    context 'any pre-seeded instance' do
      subject { SwimmingPool.all.sample }

      it 'is valid' do
        expect(subject).to be_an(SwimmingPool).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[pool_type]
      )
      # it_behaves_like(
      #   'responding to a list of methods',
      #   %i[relay? eventable? to_json]
      # )
    end
  end
end
