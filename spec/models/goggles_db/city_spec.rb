# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe City, type: :model do
    shared_examples_for 'a valid City instance' do
      it 'is valid' do
        expect(subject).to be_a(City).and be_valid
      end

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name country_code]
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
    end

    context 'any pre-seeded instance' do
      subject { City.all.limit(50).sample }
      it_behaves_like('a valid City instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:city) }
      it_behaves_like('a valid City instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Test a bunch of 'IT' cities, which are granted to have regions/subdivisions:
    City.where(country_code: 'IT').first(100).sample(10).each do |subject_city|
      let(:fixture_isos)        { subject_city.to_iso }
      let(:fixture_iso_country) { fixture_isos.first }
      let(:fixture_iso_city)    { fixture_isos.last }
      let(:fixture_subdivision) { subject_city.iso_subdivision(fixture_iso_country) }

      describe '#to_iso' do
        it 'is a non-empty Array' do
          expect(fixture_isos).to be_an(Array).and be_present
        end
        it 'contains as 1st member an ISO3166::Country' do
          expect(fixture_isos.first).to be_a(ISO3166::Country)
        end
        it 'contains as 2nd member a Cities::City' do
          expect(fixture_isos.last).to be_a(Cities::City)
        end
      end
      describe '#iso_subdivision' do
        it 'is a non-empty Array' do
          expect(fixture_subdivision).to be_an(Array).and be_present
        end
        it 'contains as 1st member an alpha-2 subdivision code' do
          expect(fixture_subdivision.first).to be_a(String)
          expect(fixture_subdivision.first.length).to eq(2)
        end
        it 'contains as 2nd member a subdivision Struct responding to \'name\'' do
          expect(fixture_subdivision.last).to be_a(Struct).and respond_to('name')
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
          expect(subject_city.localized_country_name(fixture_iso_country, 'en')).to eq('Italy')
          expect(subject_city.localized_country_name(fixture_iso_country, 'it')).to eq('Italia')
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
        it 'is a non-empty String' do
          expect(subject).to be_a(String).and be_present
        end
      end
      describe '#iso_area_code' do
        subject { subject_city.iso_area_code(fixture_subdivision) }
        it 'is a non-empty String' do
          expect(subject).to be_a(String).and be_present
        end
      end
    end

    describe '#iso_attributes' do
      let(:subject_city) { GogglesDb::City.where(country_code: 'IT').limit(50).sample }
      subject { subject_city.iso_attributes }

      it 'is a non-empty Hash' do
        expect(subject).to be_an(Hash).and be_present
      end
      it 'includes all the legacy customizable City attributes plus the additional ISO attributes' do
        expect(subject.keys).to include('id', 'name', 'latitude', 'longitude', 'country', 'country_code', 'region', 'area', 'area_code', 'zip')
      end
      # Just a couple of quick checks to verify supported locales are actually there:
      it 'allows locale override for a chosen country name translation' do
        en_attributes = subject_city.iso_attributes('en')
        it_attributes = subject_city.iso_attributes('it')
        expect(it_attributes['country']).to eq('Italia')
        expect(en_attributes['country']).to eq('Italy')
      end
    end

    describe '#to_json' do
      let(:subject_city) { City.all.limit(50).sample }
      subject { subject_city.to_json }

      it 'is a String' do
        expect(subject).to be_a(String).and be_present
      end
      it 'can be parsed without errors' do
        expect { JSON.parse(subject) }.not_to raise_error
      end
      it 'includes all the #iso_attributes' do
        expect(JSON.parse(subject).keys).to match_array(subject_city.iso_attributes.keys)
      end
    end
  end
end
