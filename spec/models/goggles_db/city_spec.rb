# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe City do
    shared_examples_for 'a valid City instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name country_code]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[
          area country latitude longitude to_iso
          iso_subdivision iso_name iso_latitude iso_longitude localized_country_name iso_country_code
          iso_region iso_area iso_area_code
          iso_attributes to_json
        ]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(50).sample }

      it_behaves_like('a valid City instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:city) }

      it_behaves_like('a valid City instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.for_name' do
      %w[forl albinea bologna carpi emilia modena reggio].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_name, %w[name area], filter_text)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Test a bunch of 'IT' cities, which are granted to have regions/subdivisions:
    described_class.where(country: 'Italy').first(50).sample(3).each do |subject_city|
      context "when testing against an existing row ('#{subject_city.name}')," do
        before do
          subject_city.to_iso # Force a init+memoize call at first
        end

        let(:fixture_isos)        { subject_city.to_iso }
        let(:fixture_iso_country) { fixture_isos.first }
        let(:fixture_iso_city)    { fixture_isos.last }

        describe '#to_iso' do
          it 'is a non-empty Array' do
            expect(fixture_isos).to be_an(Array).and be_present
          end

          it 'contains as 1st member an ISO3166::Country' do
            expect(fixture_isos.first).to be_a(ISO3166::Country)
          end

          it 'contains as 2nd member a Cities::City instance' do
            expect(fixture_isos.last).to be_a(Cities::City)
          end
        end

        describe '#iso_subdivision' do
          subject { subject_city.iso_subdivision(fixture_iso_country) }

          it 'is a non-empty Array' do
            expect(subject).to be_an(Array).and be_present
          end

          it 'contains as 1st member an alpha-2 subdivision code' do
            expect(subject.first).to be_a(String)
            expect(subject.first.length).to eq(2)
          end

          it 'contains as 2nd member a ISO3166::Subdivision responding to \'name\'' do
            expect(subject.last).to be_a(ISO3166::Subdivision).and respond_to('name')
          end
        end

        describe '#iso_name' do
          subject { subject_city.iso_name(fixture_iso_city) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end

        describe '#iso_latitude' do
          subject { subject_city.iso_latitude(fixture_iso_city) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end

        describe '#iso_longitude' do
          subject { subject_city.iso_longitude(fixture_iso_city) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end

        describe '#iso_region' do
          subject { subject_city.iso_region(fixture_iso_city, fixture_iso_country) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end

        describe '#localized_country_name' do
          subject { subject_city.localized_country_name(fixture_iso_country) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end

          it 'allows locale override for a chosen country name translation' do
            en_country_name = subject_city.localized_country_name(fixture_iso_country, 'en')
            it_country_name = subject_city.localized_country_name(fixture_iso_country, 'it')

            expect(en_country_name).to be_present
            expect(it_country_name).to be_present
            expect(en_country_name != it_country_name).to be true
          end
        end

        describe '#iso_country_code' do
          subject { subject_city.iso_country_code(fixture_iso_country) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end

        describe '#iso_area' do
          subject { subject_city.iso_area(fixture_subdivision) }

          let(:fixture_subdivision) { subject_city.iso_subdivision(fixture_iso_country) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end

        describe '#iso_area_code' do
          subject { subject_city.iso_area_code(fixture_subdivision) }

          let(:fixture_subdivision) { subject_city.iso_subdivision(fixture_iso_country) }

          it 'is a non-empty String' do
            expect(subject).to be_a(String).and be_present
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      describe '#iso_attributes' do
        subject { subject_city.iso_attributes }

        let(:subject_city) { described_class.first(100).sample }

        it 'is a non-empty Hash' do
          expect(subject).to be_an(Hash).and be_present
        end

        it 'includes just the additional ISO attributes' do
          expect(subject.keys).to include('name', 'latitude', 'longitude', 'country', 'country_code', 'region', 'area', 'area_code')
        end
        # Just a couple of quick checks to verify supported locales are actually there:

        it 'allows locale override for a chosen country name translation' do
          en_attributes = subject_city.iso_attributes('en')
          it_attributes = subject_city.iso_attributes('it')
          expect(it_attributes['country']).to be_present
          expect(en_attributes['country']).to be_present
          expect(it_attributes['country'] != en_attributes['country']).to be true
        end
      end

      describe '#minimal_attributes (override)' do
        subject(:result) { subject_city.minimal_attributes }

        %w[display_label short_label].each do |method_name|
          it "includes the decorated '#{method_name}'" do
            expect(result[method_name]).to eq(subject_city.decorate.send(method_name))
          end
        end

        it 'includes the original row attributes' do
          expect(subject.keys).to include('id', 'zip')
        end

        # rubocop:disable RSpec/NoExpectationExample
        it 'includes all the #iso_attributes' do
          hash2_includes_hash1(hash1: subject_city.iso_attributes, hash2: result)
        end
        # rubocop:enable RSpec/NoExpectationExample
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
