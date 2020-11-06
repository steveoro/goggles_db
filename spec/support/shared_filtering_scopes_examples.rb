# frozen_string_literal: true

shared_examples_for 'filtering scope for_gender_type' do |subject_class|
  context "given the chosen GenderType has any #{subject_class.to_s.pluralize} associated to it," do
    let(:chosen_filter) { GogglesDb::GenderType.send(%w[male female].sample) }
    let(:result) { subject_class.for_gender_type(chosen_filter).limit(10) }

    it "is a relation containing only #{subject_class}s belonging to the specified GenderType" do
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to all be_a(subject_class)
      expect(result.map(&:gender_type).uniq).to all eq(chosen_filter)
    end
  end
end

shared_examples_for 'filtering scope for_season_type' do |subject_class|
  context "given the chosen SeasonType has any #{subject_class.to_s.pluralize} associated to it," do
    let(:chosen_filter) { GogglesDb::SeasonType.only_masters.sample }
    let(:result) { subject_class.for_season_type(chosen_filter).limit(10) }

    it "is a relation containing only #{subject_class.to_s.pluralize} belonging to the specified SeasonType" do
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to all be_a(subject_class)
      expect(result.map(&:season_type).uniq).to all eq(chosen_filter)
    end
  end
end

# The following meta-example works best with +entity_name+ values such as:
#
# - 'team'
# - 'season'
# - 'category_type'
#
# The +subject_class+ must have a valid chain association with +entity_name+. ("Through" are supported.)
#
shared_examples_for 'filtering scope for_<ANY_ENTITY_NAME>' do |subject_class, entity_name|
  context "given the chosen #{entity_name.camelcase} has any #{subject_class.to_s.pluralize} associated to it," do
    # Find an entity_name row associated to any subject_class rows for sure by starting from
    # the inner join with the source rows themselves:
    let(:chosen_filter) do
      subject_class.includes(entity_name.to_sym).joins(entity_name.to_sym)
                   .select("#{entity_name}_id").distinct
                   .limit(20).sample
                   .send(entity_name)
    end
    let(:result) { subject_class.send("for_#{entity_name}", chosen_filter).limit(10) }

    it "is a relation containing only #{subject_class.to_s.pluralize} belonging to the specified #{entity_name.camelcase}" do
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to all be_a(subject_class)
      # Does subject class have a 1st-level relationship with 'entity_name'?
      # (:belongs_to or :has_one, no 'through's - which is handled by the 'else' case)
      if subject_class.new.respond_to?("#{entity_name}_id")
        expect(result.map(&:"#{entity_name}_id").uniq).to all eq(chosen_filter.id)
      else
        expect(result.map { |row| row.send(entity_name).id }.uniq).to all eq(chosen_filter.id)
      end
    end
  end
end

# In a bit more restricted way than the group above, the following meta-example works only
# with a list of 1st-level +entity_name+s associated with +subject_class+.
# (Not valid for :throught's relationships due to the SQL joins involved.)
#
# (Please note that 'entity_name' parameter is supposed to be SINGULAR, but the filtering verb is NOT)
#
shared_examples_for 'filtering scope for_<PLURAL_ENTITY_NAME>' do |subject_class, entity_name|
  context "given the chosen list of #{entity_name.camelcase.pluralize} has any #{subject_class.to_s.pluralize} associated to it," do
    # Find a *list* of +entity_name+ rows associated to any subject_class rows:
    # find a sure match by starting the relationship chain from the inner join with
    # the source rows themselves:
    let(:chosen_filters) do
      subject_class.includes(entity_name.to_sym).joins(entity_name.to_sym)
                   .select("#{entity_name}_id").distinct
                   .limit(10).sample(3)
                   .map(&:"#{entity_name}")
    end
    # Do not limit the result rows here, or we may encur in filtering out chosen filter IDs:
    let(:result) { subject_class.send("for_#{entity_name.pluralize}", chosen_filters) }

    it "is a relation containing only #{subject_class.to_s.pluralize} belonging to the specified #{entity_name.camelcase}" do
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to all be_a(subject_class)
      expect(result.map(&:"#{entity_name}_id").uniq.sort).to match(chosen_filters.map(&:id).sort)
    end
  end
end

shared_examples_for 'filtering scope for_years' do |subject_class|
  context "given there are #{subject_class.to_s.pluralize} defined for the filtering value," do
    let(:chosen_filter) { (2014..2019).to_a.sample(2) }
    let(:result) { subject_class.for_years(*chosen_filter).limit(10) }

    it "is a relation containing only #{subject_class.to_s.pluralize} belonging to the specified filtering value" do
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to all be_a(subject_class)
      result.map(&:header_year).uniq.each do |header_year|
        expect(header_year).to include(chosen_filter.first.to_s).or include(chosen_filter.last.to_s)
      end
    end
  end
end

shared_examples_for 'filtering scope for_year' do |subject_class|
  context "given there are #{subject_class.to_s.pluralize} defined for the filtering value," do
    let(:chosen_filter) { (2014..2019).to_a.sample }
    let(:result) { subject_class.for_year(chosen_filter).limit(10) }

    it "is a relation containing only #{subject_class.to_s.pluralize} belonging to the specified filtering value" do
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to all be_a(subject_class)
      result.map(&:header_year).uniq.each do |header_year|
        expect(header_year).to include(chosen_filter.to_s)
      end
    end
  end
end
