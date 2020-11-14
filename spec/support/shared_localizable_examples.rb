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
    it_behaves_like('responding to a list of methods', %i[code label long_label alt_label])
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
