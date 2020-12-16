# frozen_string_literal: true

# Handles both normal associations and associations with lookup entities (GogglesDb::ApplicationLookupEntity)
def compare_attributes_between(parsed_json_association_obj, association)
  # Expect associations with lookup entities to include translated labels in their to_json:
  if association.respond_to?(:lookup_attributes)
    expect(parsed_json_association_obj).to eq(JSON.parse(association.lookup_attributes.to_json))
  else
    expect(parsed_json_association_obj).to eq(JSON.parse(association.minimal_attributes.to_json))
  end
end
#-- ---------------------------------------------------------------------------
#++

shared_examples_for '#to_json when called on a valid instance' do |required_associations|
  it 'is a String' do
    expect(subject.to_json).to be_a(String).and be_present
  end
  it 'can be parsed without errors' do
    expect { JSON.parse(subject.to_json) }.not_to raise_error
  end

  describe 'the 1st-level required association' do
    let(:json_hash) { JSON.parse(subject.to_json) }
    required_associations.each do |association_name|
      it "contains the JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be_an(Hash).and be_present
        compare_attributes_between(json_hash[association_name], subject.send(association_name.to_sym))
      end
    end
  end
end

# For model associations that have lots of fields, we may resort to output just a few.
# Assumes the "synthetized association" uses a public method that has a name like '<ENTITY_attributes>'
# (as is 'meeting' => 'meeting_attributes') to obtain the Hash of fields that we'll actually use as result.
shared_examples_for '#to_json when called on a valid instance with a synthetized association' do |synth_associations|
  it 'is a String' do
    expect(subject.to_json).to be_a(String).and be_present
  end
  it 'can be parsed without errors' do
    expect { JSON.parse(subject.to_json) }.not_to raise_error
  end

  describe 'the required but synthetized association' do
    let(:json_hash) { JSON.parse(subject.to_json) }
    synth_associations.each do |association_name|
      it "contains the JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be_an(Hash).and be_present
        expect(json_hash[association_name]).to eq(JSON.parse(subject.send("#{association_name}_attributes".to_sym).to_json))
      end
    end
  end
end

shared_examples_for '#to_json when called with unset optional associations' do |optional_associations|
  it 'is a String' do
    expect(subject.to_json).to be_a(String).and be_present
  end
  it 'can be parsed without errors' do
    expect { JSON.parse(subject.to_json) }.not_to raise_error
  end

  describe 'the optional association' do
    let(:json_hash) { JSON.parse(subject.to_json) }
    optional_associations.each do |association_name|
      it "contains just the key of the JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be nil
      end
    end
  end
end

shared_examples_for '#to_json when the entity contains other optional associations with' do |optional_associations|
  it 'is a String' do
    expect(subject.to_json).to be_a(String).and be_present
  end
  it 'can be parsed without errors' do
    expect { JSON.parse(subject.to_json) }.not_to raise_error
  end

  describe 'the optional association' do
    optional_associations.each do |association_name|
      it "contains the JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be_an(Hash).and be_present
        compare_attributes_between(json_hash[association_name], subject.send(association_name.to_sym))
      end
    end
  end
end

shared_examples_for '#to_json when the entity contains collection associations with' do |collection_associations|
  collection_associations.each do |association_name|
    context "when the entity contains a collection of #{association_name}," do
      it "contains the most recent JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be_an(Array).and be_present
        expect(json_hash[association_name].count).to be <= subject.send(association_name.to_sym).count
        # Build a quick list of all the original association IDs and check that all associated objects
        # are indeed a member in this parent association list:
        unfiltered_ids = subject.send(association_name.to_sym).pluck(:id)
        expect(
          json_hash[association_name].pluck('id').uniq.all? { |id| unfiltered_ids.member?(id) }
        ).to be true
      end
    end
  end
end
