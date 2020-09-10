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
    it 'returns a kind of ActiveRecord::Relation' do
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

shared_examples_for 'having a relation with a list of models' do |attribute_name_array|
  # [ Insert Quagmire meme here: 'giggidi' :-P ]
  attribute_name_array.each do |attribute_name|
    it "responds to :#{attribute_name}" do
      expect(subject).to respond_to(attribute_name)
    end
    it "returns an instance of #{attribute_name.to_s.camelize}" do
      expect(subject.send(attribute_name)).to be_an_instance_of(attribute_name.to_s.camelize.constantize)
    end
  end
end

shared_examples_for 'belonging to a list of models' do |attribute_name_array|
  attribute_name_array.each do |attribute_name|
    it "it belongs_to :#{attribute_name}" do
      expect(subject.send(attribute_name.to_sym)).to be_a(attribute_name.to_s.camelize.constantize)
    end
  end
end
