# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'

module GogglesDb
  RSpec.describe LastSeasonId do
    describe 'the view result,' do
      subject { described_class.all }

      it 'has a positive count' do
        expect(subject.count).to be_positive
      end
    end

    describe 'any row instance,' do
      subject { described_class.all.sample }

      it 'has a valid #id field' do
        expect(subject.id).to be_positive
      end

      it_behaves_like('ApplicationRecord shared interface')
    end
  end
end
