# frozen_string_literal: true

shared_examples_for 'sorting scope by_season' do |subject_class|
  let(:result) { subject_class.by_season.limit(20) }

  it "is a #{subject_class} relation" do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(subject_class)
  end
  # Checks just the boundaries with a random middle point in between:
  it 'is ordered' do
    expect(result.first.season.begin_date).to be <= result.sample.season.begin_date
    expect(result.sample.season.begin_date).to be <= result.last.season.begin_date
  end
end

shared_examples_for 'sorting scope by_swimmer' do |subject_class|
  let(:result) { subject_class.by_swimmer.limit(20) }

  it "is a #{subject_class} relation" do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(subject_class)
  end
  it 'is ordered' do
    expect(result.first.swimmer.complete_name).to be <= result.sample.swimmer.complete_name
    expect(result.sample.swimmer.complete_name).to be <= result.last.swimmer.complete_name
  end
end

shared_examples_for 'sorting scope by_category_type' do |subject_class|
  let(:result) { subject_class.by_category_type.limit(20) }

  it "is a #{subject_class} relation" do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(subject_class)
  end
  it 'is ordered' do
    expect(result.first.category_type.code).to be <= result.sample.category_type.code
    expect(result.sample.category_type.code).to be <= result.last.category_type.code
  end
end
