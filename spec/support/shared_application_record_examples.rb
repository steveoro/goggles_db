# frozen_string_literal: true

require 'support/shared_method_existance_examples'

# Compares any 2 attributes Hashes (allegedly from any base model or association model instance
# attributes) and fails if something is different or not included in the second Hash as a corresponding match.
#
# Expects all elements from hash1 to be included and equal in value to each hash2
# corresponding item.
#
def hash2_includes_hash1(hash1:, hash2:)
  # Peculiar case for City: country (& code) from #iso_attributes will overwrite the country fields
  # from the model row with an always localized country name (which may differ from the one serialized).
  # That's the only case in which we can safely ignore the value comparison.
  expect(
    hash1.except('country', 'country_code')
          .all? { |key, value| hash2.key?(key) && (hash2[key] == value) }
  ).to be true
end
#-- ---------------------------------------------------------------------------
#++

shared_examples_for('ApplicationRecord shared interface') do
  it_behaves_like(
    'responding to a list of methods',
    %i[minimal_attributes all_associations
       single_associations multiple_associations
       to_hash to_json]
  )

  # default max_siblings = 20 (can be overridden by params); let's make this quicker:
  let(:max_siblings) { 3 }

  # Force a different locale from the default to test the localizable labels, when available
  let(:locale_override) { %i[en it].reject { |l| l == I18n.locale }.sample }

  describe '#minimal_attributes (with locale override support)' do
    let(:result) { subject.minimal_attributes(locale_override) }

    it 'is an Hash' do
      expect(result).to be_an(Hash).and be_present
    end

    # rubocop:disable RSpec/NoExpectationExample
    it 'includes the attributes Hash without the timestamps and the lock_version' do
      min_attrs_hash = subject.attributes.except('lock_version', 'created_at', 'updated_at')
      hash2_includes_hash1(hash1: min_attrs_hash, hash2: result)
    end
    # rubocop:enable RSpec/NoExpectationExample

    it 'includes the localization labels if it\'s a Localizable entity (responding to the methods)' do
      if subject.respond_to?(:label) && subject.respond_to?(:long_label) && subject.respond_to?(:alt_label)
        expect(result).to have_key('label')
          .and have_key('long_label').and have_key('alt_label')

        expect(result['label']).to eq(subject.label(locale_override))
        expect(result['long_label']).to eq(subject.long_label(locale_override))
        expect(result['alt_label']).to eq(subject.alt_label(locale_override))
      end
    end
  end

  describe '#all_associations' do
    let(:result) { subject.all_associations }

    it 'is an Array' do
      expect(result).to be_an(Array)
    end

    it 'is the map of all the associations names as strings' do
      expect(result).to match_array(subject.class.reflect_on_all_associations.map(&:name).map(&:to_s))
    end

    %i[has_many has_one belongs_to].each do |filtering_sym|
      describe "when using a '#{filtering_sym}' filtering parameter," do
        it "is the map of just the '#{filtering_sym}' associations names" do
          expect(subject.all_associations(filtering_sym))
            .to match_array(subject.class.reflect_on_all_associations(filtering_sym).map(&:name).map(&:to_s))
        end
      end
    end
  end

  describe '#single_associations' do
    let(:result) { subject.single_associations }

    # Can't say nothing more here as this is overridden in siblings most of the times:
    it 'is an Array' do
      expect(result).to be_an(Array)
    end
  end

  describe '#multiple_associations' do
    let(:result) { subject.multiple_associations }

    # Can't say nothing more here as this is overridden in siblings most of the times:
    it 'is an Array' do
      expect(result).to be_an(Array)
    end
  end

  describe '#to_hash' do
    let(:result) { subject.to_hash(max_siblings: max_siblings, locale: locale_override) }

    it 'supports both :locale override & :max_siblings as options, returning always an Hash' do
      expect(result).to be_an(Hash).and be_present
    end

    # rubocop:disable RSpec/NoExpectationExample
    it 'includes the #minimal_attributes' do
      hash2_includes_hash1(hash1: subject.minimal_attributes(locale_override), hash2: result)
    end
    # rubocop:enable RSpec/NoExpectationExample

    it 'includes the localization labels if it\'s a Localizable entity (responding to its methods)' do
      if subject.respond_to?(:label) && subject.respond_to?(:long_label) && subject.respond_to?(:alt_label)
        expect(result.keys).to include('label', 'long_label', 'alt_label')

        expect(result['label']).to eq(subject.label(locale_override))
        expect(result['long_label']).to eq(subject.long_label(locale_override))
        expect(result['alt_label']).to eq(subject.alt_label(locale_override))
      end
    end

    it 'includes the #minimal_attributes (or the summarized version if available) for any set row of a 1:1 association' do
      subject.single_associations.each do |key|
        next unless subject.send(key).respond_to?(:minimal_attributes)

        expect(result).to have_key(key.to_s)
        custom_attr_helper = "#{key}_attributes" # (standardized name for the helper)
        # Subject has a bespoke summarized attribute helper for this association?
        if subject.respond_to?(custom_attr_helper)
          expect(result[key]).to eq(subject.send(custom_attr_helper))
        else
          expect(result[key]).to eq(subject.send(key).minimal_attributes(locale_override))
        end
      end
    end

    it 'includes the #minimal_attributes for any set row of a 1:N association' do
      subject.multiple_associations.each do |key|
        domain = subject.send(key)
        next unless domain.respond_to?(:map) && domain.respond_to?(:first) && domain.respond_to?(:count)
        next unless domain.count.positive?

        expect(result).to have_key(key.to_s)
        expect(result[key].count).to eq(domain.first(max_siblings).count)
        expect(result[key].first).to be_present
        expect(result[key].first['id']).to eq(domain.first.id)
        # (Shortcut: won't check each #minimal_attributes here)
      end
    end
  end

  describe '#to_json' do
    let(:result) { subject.to_json(max_siblings: max_siblings) }

    it 'is a String' do
      expect(result).to be_a(String).and be_present
    end

    it 'can be parsed without errors' do
      expect { JSON.parse(result) }.not_to raise_error
    end

    it 'is equal to the JSONified output of #to_hash' do
      expect(result).to eq(subject.to_hash(max_siblings: max_siblings).to_json)
    end
  end
end
#-- ---------------------------------------------------------------------------
#++

shared_examples_for '#to_hash when the entity has any 1:1 required association with' do |required_associations|
  let(:result) { subject.to_hash(max_siblings: 3) } # limit sibling rows

  required_associations.each do |association_name|
    it "contains the attributes of its #{association_name}" do
      expect(result[association_name]).to be_an(Hash).and be_present
      hash2_includes_hash1(hash1: result[association_name], hash2: subject.send(association_name).minimal_attributes)
    end
  end
end

shared_examples_for '#to_hash when the entity has any 1:1 optional association with' do |optional_associations|
  let(:result) { subject.to_hash(max_siblings: 3) } # limit sibling rows

  optional_associations.each do |association_name|
    it "contains the attributes of its '#{association_name}' *only* if the association is set" do
      if subject.send(association_name).present?
        expect(result).to have_key(association_name.to_s)
        expect(result[association_name]).to be_an(Hash).and be_present
        hash2_includes_hash1(hash1: result[association_name], hash2: subject.send(association_name).minimal_attributes)
      else
        expect(result).not_to have_key(association_name.to_s)
      end
    end
  end
end

# For model associations that have lots of fields, we may resort to output just a few.
# Assumes the "summarized association" uses a public method that has a name like '<ENTITY>_attributes'
# (as in 'meeting' => meeting_attributes) which "summarizes" the original (minimal_) attributes output.
shared_examples_for '#to_hash when the entity has any 1:1 summarized association with' do |synth_associations|
  let(:result) { subject.to_hash(max_siblings: 3) } # limit sibling rows

  synth_associations.each do |association_name|
    it "contains the attributes of its #{association_name}" do
      expect(result[association_name]).to be_an(Hash).and be_present
      expect(result[association_name]).to eq(subject.send("#{association_name}_attributes"))
    end
  end
end

shared_examples_for '#to_hash when the entity has any 1:N collection association with' do |collection_associations|
  let(:result) { subject.to_hash(max_siblings: 3) } # limit sibling rows

  collection_associations.each do |association_name|
    it "contains a list of Hash, each one with the 'summarized' attributes of its #{association_name}" do
      expect(result[association_name]).to be_an(Array).and be_present
      expect(result[association_name].count).to be <= 3 # (max_siblings)
      # Build a quick list of all the original association IDs and check that all associated objects
      # are indeed a member in this parent association list:
      unfiltered_ids = subject.send(association_name.to_sym).first(3).pluck(:id)
      expect(
        result[association_name].pluck('id').uniq.all? { |id| unfiltered_ids.member?(id) }
      ).to be true
    end
  end
end
#-- ---------------------------------------------------------------------------
#++
