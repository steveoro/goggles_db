# frozen_string_literal: true

# This applies to scopes like 'by_rank' or 'by_date', where the +value_name+ is
# a direct sibling of the +subject_class+ instance. (Shallow depth association)
shared_examples_for 'sorting scope by_<ANY_VALUE_NAME>' do |subject_class, value_name, comparable_method|
  let(:result) { subject_class.send("by_#{value_name}").limit(20) }

  it "is a #{subject_class} relation" do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(subject_class)
  end
  it 'is ordered' do
    expect(result.first.send(comparable_method)).to be <= result.sample.send(comparable_method)
    expect(result.sample.send(comparable_method)).to be <= result.last.send(comparable_method)
  end
end

# Same as above (shallow depth association) but supporting an externally prepared 'result'.
shared_examples_for 'sorting scope by_<ANY_VALUE_NAME> (with prepared result)' do |subject_class, comparable_method|
  it "is a #{subject_class} relation" do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(subject_class)
  end
  it 'is ordered' do
    expect(result.first.send(comparable_method)).to be <= result.sample.send(comparable_method)
    expect(result.sample.send(comparable_method)).to be <= result.last.send(comparable_method)
  end
end

# This applies to other scopes scopes like 'by_swimmer' or 'by_season', where
# the +comparable_method+ is a sibling of the +entity_name+ instance. (1st-level association)
shared_examples_for 'sorting scope by_<ANY_ENTITY_NAME>' do |subject_class, entity_name, comparable_method|
  let(:result) { subject_class.send("by_#{entity_name}").limit(20) }

  it "is a #{subject_class} relation" do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(subject_class)
  end
  it 'is ordered' do
    expect(result.first.send(entity_name).send(comparable_method)).to be <= result.sample.send(entity_name).send(comparable_method)
    expect(result.sample.send(entity_name).send(comparable_method)).to be <= result.last.send(entity_name).send(comparable_method)
  end
end
