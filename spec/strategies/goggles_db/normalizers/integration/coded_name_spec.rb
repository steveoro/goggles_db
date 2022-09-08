# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe Normalizers::CodedName, type: :integration do
    [
      ['11° Trofeo Buonconsiglio Nuoto', 11, GogglesDb::EditionType::ORDINAL_ID],
      ['8° Trofeo Swim4Life', 8, GogglesDb::EditionType::ORDINAL_ID],
      ['VI Trofeo Vittorino da Feltre', 6, GogglesDb::EditionType::ROMAN_ID],
      ['Trofeo 25 forum master sprint', 25, GogglesDb::EditionType::YEARLY_ID],
      ['Campionato Regionale Master 2020 - ABR', 2020, GogglesDb::EditionType::YEARLY_ID],
      ['Campionato Regionale Master 2021 - LAZ - 1ª parte', 2021, GogglesDb::EditionType::YEARLY_ID],
      ['Campionato Regionale Master 2022 - TRE AA', 2022, GogglesDb::EditionType::YEARLY_ID],
      ['Meeting di Primavera 2022', 2022, GogglesDb::EditionType::YEARLY_ID],
      ['Manifestazione Estiva 2022', 2022, GogglesDb::EditionType::YEARLY_ID],
      ['1a prova Circuito Regionale CSI', 1, GogglesDb::EditionType::SEASONAL_ID],
      ['5a Prova Finale Regionale CSI', 5, GogglesDb::EditionType::SEASONAL_ID],
      ['Sardegna Nuota 2022', 2022, GogglesDb::EditionType::YEARLY_ID]
    ].each do |description, expected_edition, expected_type_id|
      context "self.edition_split_from('#{description}')" do
        let(:results) { described_class.edition_split_from(description) }

        it 'returns the expected edition number' do
          expect(results.first).to eq(expected_edition)
        end

        it 'returns a non-empty description' do
          expect(results.second).to be_present
        end

        it 'returns the description stripped of its edition number (if present)' do
          # DEBUG
          # puts "'#{description}' => #{results.inspect}"
          expect(results.second).not_to include(expected_edition.to_s)
        end

        it 'returns the expected edition type ID' do
          expect(results.third).to eq(expected_type_id)
        end
      end
    end
  end
end
