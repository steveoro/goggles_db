# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe Normalizers::CityName, type: :strategy do
    describe '#process()' do
      context 'with valid parameters,' do
        subject { described_class.new(fixture_city) }

        let(:fixture_city) { GogglesDb::City.first(100).sample }

        it 'returns the normalized city' do
          expect(subject.process).to be_a(GogglesDb::City)
        end
      end

      # Integration check:
      context 'when run on cities that are already normalized,' do
        # == Known issues: ==
        # - "NIBIONNO" (ID: 105) => missing from ISO DB
        # - "LUMEZZANE" (ID: 132) => missing from ISO DB
        # - "Sedi diverse" (ID: 176) => must be ignored
        # All other cities with ID < 182 are already normalized and must not be touched
        # by the normalizer.
        GogglesDb::City.where('(id NOT IN (?)) AND (id < 182)', [105, 132, 176])
                       .sample(30)
                       .each do |city|
          it "does NOT change the city at all (tested on ID #{city.id})" do
            norm_city = described_class.new(city).process
            expect(norm_city.has_changes_to_save?).to be false
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++

    describe '#output_if_differs?()' do
      %w[
        Modena Bologna Parma Carpi Riccione Brescia Desenzano Milano Forlì
      ].each do |city_name|
        context 'when a column differs in value from its corresponding ISO attribute,' do
          it "returns true (tested on #{city_name}, empty attributes)" do
            # Do not use RSpec memoized values here (we need a clean slate each loop):
            fixture_city = GogglesDb::City.new(name: city_name, country: 'Italy', country_code: 'IT')
            base_subject = described_class.new(fixture_city)
            expect(base_subject.output_if_differs?('latitude', 'latitude')).to be true
            expect(base_subject.output_if_differs?('longitude', 'longitude')).to be true
          end
        end

        context 'when a column has the same value of its corresponding ISO attribute,' do
          it "returns false (tested on #{city_name}, name attribute)" do
            fixture_city = GogglesDb::City.new(name: city_name, country: 'Italy', country_code: 'IT')
            base_subject = described_class.new(fixture_city)
            expect(base_subject.output_if_differs?('name', 'name')).to be false
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
