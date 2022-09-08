# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_db_finders_base_strategy_examples'

module GogglesDb
  RSpec.describe Normalizers::CodedName, type: :strategy do
    describe 'self.for_meeting()' do
      let(:descriptions) { YAML.load_file(GogglesDb::Engine.root.join('spec/fixtures/normalizers/descriptions-212.yml')) }
      let(:addresses) { YAML.load_file(GogglesDb::Engine.root.join('spec/fixtures/normalizers/addresses-212.yml')) }

      describe 'with valid parameters,' do
        let(:city_names) { addresses.map { |txt| txt.split(' - ').last.split(' (').first } }

        it 'returns a non-empty, valid code String (<= 50 chars)' do
          descriptions.each do |description|
            result = described_class.for_meeting(description, city_names.sample)
            expect(result).to be_a(String)
            expect(result).to be_present
            expect(result.length).to be <= 50
            # DEBUG
            # puts "code: '#{result}'"
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++

    describe 'self.for_pool()' do
      let(:venues) { YAML.load_file(GogglesDb::Engine.root.join('spec/fixtures/normalizers/venues-212.yml')) }
      let(:pool_type_code) { %w[25 50].sample }
      let(:addresses) { YAML.load_file(GogglesDb::Engine.root.join('spec/fixtures/normalizers/addresses-212.yml')) }

      describe 'with valid parameters,' do
        let(:city_names) { addresses.map { |txt| txt.split(' - ').last.split(' (').first } }

        it 'returns a non-empty, valid code String (<= 50 chars)' do
          venues.each do |pool_name|
            result = described_class.for_pool(pool_name, city_names.sample, pool_type_code)
            expect(result).to be_a(String)
            expect(result).to be_present
            expect(result.length).to be <= 50
            # DEBUG
            # puts "code: '#{result}'"
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++

    describe 'self.edition_split_from()' do
      context 'when parsing a description without any edition number,' do
        # base default: "None", but precedence may vary
        [
          ['Meeting Vattelapesca', 0, GogglesDb::EditionType::NONE_ID],
          ['Campionato Regionale della Pallacorda', 0, GogglesDb::EditionType::YEARLY_ID],
          ['Memorial Paolo Rompiglioni', 0, GogglesDb::EditionType::NONE_ID],
          ['Meeting di Mio Zio', 0, GogglesDb::EditionType::NONE_ID]
        ].each do |description, expected_edition, expected_type_id|
          describe "self.edition_split_from('#{description}')" do
            let(:results) { described_class.edition_split_from(description) }

            it 'returns the expected edition number' do
              expect(results.first).to eq(expected_edition)
            end

            it 'returns a non-empty description' do
              expect(results.second).to be_present
            end

            it 'returns the description stripped of its edition number (if present)' do
              expect(results.second).not_to include(expected_edition.to_s)
            end

            it 'returns the expected edition type ID' do
              expect(results.third).to eq(expected_type_id)
            end
          end
        end
      end

      context 'when parsing a description that includes an yearly edition number at the end,' do
        [
          ['Meeting Vattelapesca 2019', 2019, GogglesDb::EditionType::YEARLY_ID],
          ['Campionato Regionale della Pallacorda 2020', 2020, GogglesDb::EditionType::YEARLY_ID],
          ['Memorial Paolo Rompiglioni 2021', 2021, GogglesDb::EditionType::YEARLY_ID],
          ['Meeting di Mio Zio 2022', 2022, GogglesDb::EditionType::YEARLY_ID]
        ].each do |description, expected_edition, expected_type_id|
          describe "self.edition_split_from('#{description}')" do
            let(:results) { described_class.edition_split_from(description) }

            it 'returns the expected edition number' do
              expect(results.first).to eq(expected_edition)
            end

            it 'returns a non-empty description' do
              expect(results.second).to be_present
            end

            it 'returns the description stripped of its edition number (if present)' do
              expect(results.second).not_to include(expected_edition.to_s)
            end

            it 'returns the expected edition type ID' do
              expect(results.third).to eq(expected_type_id)
            end
          end
        end
      end

      context 'when parsing a description that includes an edition number,' do
        # Test also various precedence variations:
        [
          # base default: Roman, but precedence may vary
          ['Ia Prova Camp. Regionale CSI', 1, GogglesDb::EditionType::SEASONAL_ID],
          ['IIo Meeting della Polenta', 2, GogglesDb::EditionType::ROMAN_ID],
          ['III Campionato del Rutto Atomico', 3, GogglesDb::EditionType::ROMAN_ID],
          ['IV Meeting della Stanchezza 2010', 4, GogglesDb::EditionType::ROMAN_ID],
          ['Va Finale di ChiNonSaScrivereINumeriRomani', 5, GogglesDb::EditionType::SEASONAL_ID],
          ['VI Memorial dei miei Scatoloni', 6, GogglesDb::EditionType::ROMAN_ID],
          ['VII° Campionato MaAncheNo', 7, GogglesDb::EditionType::ROMAN_ID],
          ['VIII Meeting SiamoPazzi 2002', 8, GogglesDb::EditionType::ROMAN_ID],
          # NOTE: IIX won't be correctly parsed as "8" but as "2"

          # base default: Ordinal, but precedence may vary
          ['9a Prova Camp. Regionale CSI', 9, GogglesDb::EditionType::SEASONAL_ID],
          ['10° Finale Regionale CSI 2018-2019', 10, GogglesDb::EditionType::SEASONAL_ID],
          ['11^ Campionato del Rutto Atomico', 11, GogglesDb::EditionType::ORDINAL_ID],
          ['12o Meeting della Variabilità', 12, GogglesDb::EditionType::ORDINAL_ID],
          ['13 Meeting della Stanchezza 1997', 13, GogglesDb::EditionType::ORDINAL_ID],
          ['14a Gara Mondiale Nata nel 2003', 14, GogglesDb::EditionType::ORDINAL_ID],
          ['15° Finale Regionale della Polenta 2022', 15, GogglesDb::EditionType::SEASONAL_ID]
        ].each do |description, expected_edition, expected_type_id|
          describe "self.edition_split_from('#{description}')" do
            let(:results) { described_class.edition_split_from(description) }

            it 'returns the expected edition number' do
              expect(results.first).to eq(expected_edition)
            end

            it 'returns a non-empty description' do
              expect(results.second).to be_present
            end

            it 'returns the description stripped of its edition number (if present)' do
              # Let's use the fixture format above as a shortcut here by assuming it always has the edition up front:
              edition_string = description.split.first
              expect(results.second).not_to include(edition_string)
            end

            it 'returns the expected edition type ID' do
              expect(results.third).to eq(expected_type_id)
            end
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
