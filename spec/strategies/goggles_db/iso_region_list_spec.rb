# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe IsoRegionList, type: :strategy do
    it_behaves_like(
      'responding to a list of methods',
      %i[fetch]
    )
  end

  shared_examples_for 'IsoRegionList properly defined' do
    context 'when fetching 0' do
      it 'is unknown (\'?\')' do
        expect(subject.fetch(0)).to eq('?')
      end
    end

    context 'when fetching an invalid index' do
      it 'is unknown (\'?\')' do
        expect(subject.fetch(30)).to eq('?')
        expect(subject.fetch(100)).to eq('?')
      end
    end

    context 'when fetching a known index' do
      it 'returns the expected name' do
        expect(subject.fetch('5')).to eq('Emilia-Romagna')
        expect(subject.fetch('05')).to eq('Emilia-Romagna')
        expect(subject.fetch(5)).to eq('Emilia-Romagna')
        expect(subject.fetch(1)).to eq('Abruzzo')
        expect(subject.fetch(4)).to eq('Campania')
        expect(subject.fetch(6)).to eq('Friuli Venezia Giulia')
        expect(subject.fetch(7)).to eq('Lazio')
        expect(subject.fetch(15)).to eq('Sicilia')
        expect(subject.fetch(16)).to eq('Toscana')
        expect(subject.fetch(17)).to eq('Trentino-Alto Adige')
        expect(subject.fetch(19)).to eq('Valle d\'Aosta')
        expect(subject.fetch(20)).to eq('Veneto')
      end
    end
  end

  describe '#fetch' do
    context 'for the default country_code,' do
      subject { IsoRegionList.new }

      it_behaves_like 'IsoRegionList properly defined'
    end

    context 'for a known existing country_code,' do
      subject { IsoRegionList.new('IT') }

      it_behaves_like 'IsoRegionList properly defined'
    end
  end
end
