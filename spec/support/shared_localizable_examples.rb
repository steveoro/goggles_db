# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

# REQUIRES/USES:
# - subject: a model row instance of the described_class
shared_examples_for 'a text translation method that accepts current locale override' do |method_name|
  it 'is a non-empty string' do
    expect(subject.send(method_name)).to be_a(String).and be_present
  end

  it 'supports current locale override as parameter' do
    expect(subject.send(method_name, :it)).to be_a(String).and be_present
  end
end

# REQUIRES/USES:
# - subject: a model row instance of the described_class
shared_examples_for 'Localizable' do
  # Describes the requistes of the including class and the outcome of the module inclusion:
  context 'by including this concern, the sibling:' do
    it 'is a valid instance of the same class' do
      expect(subject).to be_a(described_class).and be_valid
    end

    it_behaves_like('responding to a list of class methods', %i[table_name])
    # *Note*
    # Adding here 'attributes' to the list of methods to assert Concern inclusion is made only
    # inside siblings of ActiveRecord::Base. (Examples will fail otherwise.)
    it_behaves_like(
      'responding to a list of methods',
      %i[attributes code label long_label alt_label]
    )

    describe '#minimal_attributes' do
      let(:result) { subject.minimal_attributes }

      it 'is an Hash' do
        expect(result).to be_an(Hash).and be_present
      end

      it 'always includes the basic attribute keys' do
        expect(result.keys).to include('id', 'code')
        expect(result['id']).to eq(subject.id)
        expect(result['code']).to eq(subject.code)
      end

      it 'always includes the additional localized labels' do
        expect(result.keys).to include('label', 'long_label', 'alt_label')
        expect(result['label']).to eq(subject.label)
        expect(result['long_label']).to eq(subject.long_label)
        expect(result['alt_label']).to eq(subject.alt_label)
      end

      # Make sure a fallback default is always present:
      describe '#alt_label' do
        it "never starts with 'translation missing:'" do
          expect(result['alt_label']).not_to start_with('translation missing:')
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
