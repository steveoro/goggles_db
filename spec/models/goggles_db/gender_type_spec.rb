# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe GenderType, type: :model do
    describe 'self.male' do
      it 'is an instance of GenderType with a male code ID' do
        expect(GenderType.male).to be_a(GenderType).and be_valid
        expect(GenderType.male).to be_male
      end
    end

    describe 'self.female' do
      it 'is an instance of GenderType with a female code ID' do
        expect(GenderType.female).to be_a(GenderType).and be_valid
        expect(GenderType.female).to be_female
      end
    end

    describe 'self.intermixed' do
      it 'is an instance of GenderType with a female code ID' do
        expect(GenderType.intermixed).to be_a(GenderType).and be_valid
        expect(GenderType.intermixed.id).to eq(GogglesDb::GenderType::INTERMIXED_ID)
      end
    end

    describe 'self.validate_cached_rows' do
      it 'does not raise any errors' do
        expect { GenderType.validate_cached_rows }.not_to raise_error
      end
    end
  end
end
