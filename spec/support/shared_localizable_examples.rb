# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

shared_examples_for 'a text translation method that accepts current locale override' do |method_name|
  it 'is a non-empty string' do
    expect(subject.send(method_name)).to be_a(String).and be_present
  end
  it 'supports current locale override as parameter' do
    expect(subject.send(method_name, :it)).to be_a(String).and be_present
  end
end

shared_examples_for 'Localizable' do
  # Describes the requistes of the including class and the outcome of the module inclusion:
  context 'by including this concern, the sibling:' do
    it_behaves_like('responding to a list of class methods', %i[table_name])
    # *Note*
    # Adding here 'attributes' to the list of methods shall enforce Concern inclusion only
    # inside siblings of ActiveRecord::Base.
    #
    # Even if some of the following examples are stored inside AbstractLookupEntity,
    # by checking them below in this shared group, we'll apply the specs to any sibling
    # that behaves_like 'Localizable'.
    it_behaves_like(
      'responding to a list of methods',
      %i[attributes to_json code label long_label alt_label]
    )

    describe '#lookup_attributes' do
      it 'is an Hash' do
        expect(subject.lookup_attributes).to be_an(Hash).and be_present
      end
      it 'includes the basic attribute keys' do
        expect(subject.lookup_attributes.keys).to include('id', 'code')
      end
      it 'includes also the additional localized labels' do
        expect(subject.lookup_attributes.keys).to include('label', 'long_label', 'alt_label')
      end

      [nil, :it, :en].each do |locale_sym|
        let(:result) { subject.lookup_attributes(locale_sym) }
        it 'allows overriding the locale with a parameter' do
          expect(result).to be_an(Hash)
        end
        it 'always includes the additional localized labels as members' do
          expect(result).to have_key('label')
          expect(result).to have_key('long_label')
          expect(result).to have_key('alt_label')
          expect(result['label']).to be_a(String).and be_present
          expect(result['long_label']).to be_a(String).and be_present
          expect(result['alt_label']).to be_a(String).and be_present
        end
        describe '#alt_label' do
          # Also: "it should never start with 'translation missing:'"
          it 'defaults to the label text when the translation is missing' do
            expect(result['alt_label']).not_to start_with('translation missing:')
          end
        end
      end
    end

    describe '#to_json' do
      it 'is a String' do
        expect(subject.to_json).to be_a(String).and be_present
      end
      it 'can be parsed without errors' do
        expect { JSON.parse(subject.to_json) }.not_to raise_error
      end

      [nil, :it, :en].each do |locale_sym|
        let(:result) { JSON.parse(subject.to_json(locale: locale_sym)) }
        it 'allows overriding the locale as an option returning always an Hash when parsed' do
          expect(result).to be_an(Hash)
        end
        it 'includes the additional localized labels as members' do
          expect(result).to have_key('label')
          expect(result).to have_key('long_label')
          expect(result).to have_key('alt_label')
          expect(result['label']).to be_a(String).and be_present
          expect(result['long_label']).to be_a(String).and be_present
          expect(result['alt_label']).to be_a(String).and be_present
        end
      end
    end
  end

  describe '#code' do
    it 'is a non-empty string' do
      expect(subject.code).to be_a(String).and be_present
    end
  end

  describe '#label' do
    it_behaves_like('a text translation method that accepts current locale override', :label)
  end

  describe '#long_label' do
    it_behaves_like('a text translation method that accepts current locale override', :long_label)
  end

  describe '#alt_label' do
    it_behaves_like('a text translation method that accepts current locale override', :alt_label)
  end
end
