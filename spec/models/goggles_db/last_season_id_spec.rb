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

      it 'supports ordered relation helpers without MissingRequiredOrderError' do
        expect { described_class.first }.not_to raise_error
        expect { described_class.last }.not_to raise_error
      end

      it 'returns rows whose ids reference existing seasons' do
        expect(subject.pluck(:id)).to all(be_positive)
        expect(Season.where(id: subject.pluck(:id)).count).to eq(subject.count)
      end
    end

    describe 'any row instance,' do
      subject { described_class.all.sample }

      it 'has a valid #id field' do
        expect(subject.id).to be_positive
      end

      it 'is read-only' do
        expect(subject).to be_readonly
      end

      it 'belongs to a season matching its id' do
        expect(subject.season).to be_a(Season)
        expect(subject.season.id).to eq(subject.id)
      end

      it_behaves_like('ApplicationRecord shared interface')
    end
  end
end
