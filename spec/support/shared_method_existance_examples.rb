# frozen_string_literal: true

shared_examples_for 'responding to a list of class methods' do |method_name_array|
  method_name_array.each do |method_name|
    it "responds to ##{method_name}" do
      expect(subject.class).to respond_to(method_name)
    end
  end
end

shared_examples_for 'having a list of scopes with no parameters' do |method_name_array|
  it_behaves_like 'responding to a list of class methods', method_name_array

  method_name_array.each do |method_name|
    it "returns #{method_name.to_s.camelcase}'s ActiveRecord::Relation" do
      expect(subject.class.send(method_name)).to be_a_kind_of(ActiveRecord::Relation)
    end
  end
end

shared_examples_for 'responding to a list of methods' do |method_name_array|
  method_name_array.each do |method_name|
    it "responds to ##{method_name}" do
      expect(subject).to respond_to(method_name)
    end
  end
end

shared_examples_for 'having one or more required & present attributes (invalid if missing)' do |attribute_name_array|
  attribute_name_array.each do |member_name|
    it "is has a ##{member_name}" do
      expect(subject).to respond_to(member_name)
      expect(subject.send(member_name)).to be_present
    end

    it "is not valid without ##{member_name}" do
      subject.send("#{member_name}=", nil)
      expect(subject).not_to be_valid
    end
  end
end

shared_examples_for 'having one or more required associations' do |attribute_name_array|
  it_behaves_like 'responding to a list of methods', attribute_name_array

  attribute_name_array.each do |attribute_name|
    it "returns a sibling of GogglesDb::ApplicationRecord (#{attribute_name.to_s.camelcase})" do
      expect(subject.send(attribute_name)).to be_a_kind_of(GogglesDb::ApplicationRecord)
    end
  end
end
