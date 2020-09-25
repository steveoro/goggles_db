# frozen_string_literal: true

shared_examples_for '#to_json when called on a valid model instance with' do |required_associations|
  it 'is a String' do
    expect(subject.to_json).to be_a(String).and be_present
  end

  it 'can be parsed without errors' do
    expect { JSON.parse(subject.to_json) }.not_to raise_error
  end

  context 'regarding the 1st-level required associations,' do
    let(:json_hash) { JSON.parse(subject.to_json) }

    required_associations.each do |association_name|
      it "contains the JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be_an(Hash).and be_present
        expect(json_hash[association_name]).to eq(JSON.parse(subject.send(association_name.to_sym).attributes.to_json))
      end
    end
  end
end

shared_examples_for '#to_json when the entity contains other optional associations with' do |optional_associations|
  optional_associations.each do |association_name|
    it "contains the JSON details of its #{association_name}" do
      expect(json_hash[association_name]).to be_an(Hash).and be_present
      expect(json_hash[association_name]).to eq(
        JSON.parse(subject.send(association_name.to_sym).attributes.to_json)
      )
    end
  end
end

shared_examples_for '#to_json when the entity contains collection associations with' do |collection_associations|
  collection_associations.each do |association_name|
    context "when the entity contains a collection of #{association_name}," do
      it "contains the most recent JSON details of its #{association_name}" do
        expect(json_hash[association_name]).to be_an(Array).and be_present
        expect(json_hash[association_name].count).to be <= subject.send(association_name.to_sym).count
        # Build a quick list of all the original association IDs and check that all recent associated objects
        # are indeed a member in this parent association list:
        unfiltered_ids = subject.send(association_name.to_sym).pluck(:"#{association_name}.id")
        expect(
          json_hash[association_name].pluck('id').uniq.all? { |id| unfiltered_ids.member?(id) }
        ).to be true
      end
    end
  end
end
