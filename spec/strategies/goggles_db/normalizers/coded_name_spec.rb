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
        let(:descriptions) do
          [
            'Meeting Vattelapesca',
            'Campionato Regionale della Pallacorda',
            'Memorial Paolo Rompiglioni',
            'Finale di Mio Zio'
          ]
        end

        it 'returns the correct (0) edition number as first result item and the whole description as second' do
          descriptions.each do |description|
            result, split_desc = described_class.edition_split_from(description)
            expect(result).to be_zero
            expect(split_desc).to be_a(String)
            expect(split_desc).to be_present
            expect(description).to eq(split_desc)
          end
        end
      end

      context 'when parsing a description that includes an yearly edition number at the end,' do
        let(:descriptions) do
          [
            'Meeting Vattelapesca 2019',
            'Campionato Regionale della Pallacorda 2020',
            'Memorial Paolo Rompiglioni 2021',
            'Finale di Mio Zio 2022'
          ]
        end

        it 'returns the correct edition number as first result item and the whole description as second' do
          descriptions.each_with_index do |description, index|
            result, split_desc = described_class.edition_split_from(description)
            expect(result).to eq(2019 + index)
            expect(split_desc).to be_a(String)
            expect(split_desc).to be_present
            expect(description).to include(split_desc)
          end
        end
      end

      context 'when parsing a description that includes an edition number (either Roman or ordinal),' do
        let(:descriptions) do
          [
            # Roman
            'Ia Prova Camp. Regionale CSI',
            'IIo Meeting della Polenta',
            'III Campionato del Rutto Atomico',
            'IV Meeting della Stanchezza 2010',
            'Va Finale di ChiNonSaScrivereINumeriRomani',
            'VI Memorial dei miei Scatoloni',
            'VII° Campionato MaAncheNo',
            'IIX Meeting SiamoPazzi 2002',

            # Ordinal
            '9a Prova Camp. Regionale CSI',
            '10° Finale Regionale CSI 2018-2019',
            '11^ Campionato del Rutto Atomico',
            '12o Meeting della Variabilità',
            '13 Meeting della Stanchezza 1997',
            '14a Gara Mondiale Nata nel 2003',
            '15° Finale Regionale della Polenta 2022'
          ]
        end

        it 'returns the correct edition number as first result item and part of the description as second' do
          descriptions.each_with_index do |description, index|
            result, split_desc = described_class.edition_split_from(description)
            expect(result).to eq(index + 1)
            expect(split_desc).to be_a(String)
            expect(split_desc).to be_present
            expect(description).to include(split_desc)
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
