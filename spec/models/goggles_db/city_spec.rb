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
          area country latitude longitude
          to_iso iso_attributes to_json
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

    describe '#to_iso' do
      subject { City.all.limit(50).sample.to_iso }

      it 'is a non-empty Array' do
        expect(subject).to be_an(Array).and be_present
      end
      it 'contains an ISO3166::Country and a Cities::City' do
        expect(subject.first).to be_a(ISO3166::Country)
        expect(subject.last).to be_a(Cities::City)
      end
    end

    describe '#iso_attributes' do
      # The first 50 seeded cities have all country code 'IT': this is used for the quick'n'ugly
      # locale override check below.
      let(:subject_city) { City.all.limit(50).sample }
      subject { subject_city.iso_attributes }

      it 'is a non-empty Hash' do
        expect(subject).to be_an(Hash).and be_present
      end
      it 'includes all the legacy customizable City attributes plus the additional ISO attributes' do
        expect(subject.keys).to include('id', 'created_at', 'updated_at', 'name', 'latitude', 'longitude',
                                        'country', 'country_code', 'area', 'area_code', 'zip')
      end
      # Just a couple of checks to verify supported locales are there:
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
