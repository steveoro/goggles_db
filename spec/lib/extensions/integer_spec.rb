# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

describe 'Roman numeral extension for Integer', type: :model do
  context 'given a valid Integer' do
    subject { (rand * 1000).to_i }

    it_behaves_like('responding to a list of methods', %i[to_roman])
    it_behaves_like('responding to a list of class methods', %i[from_roman])

    %w[I II III IV V VI VII VIII IX X
       XI XII XIII XIV XV XVI XVII XVIII XIX XX
       XXI XXII XXIII XXIV XXV XXVI XXVII XXVIII XXIX XXX
       XXXI XXXII XXXIII XXXIV XXXV XXXVI XXXVII XXXVIII XXXIX XL
       XLI XLII XLIII XLIV XLV XLVI XLVII XLVIII XLIX L
       LI LII LIII LIV LV LVI LVII LVIII LIX LX].each_with_index do |roman_number, index|
      describe "#to_roman(#{index + 1})" do
        it "returns its text roman value (#{roman_number})" do
          expect((index + 1).to_roman).to eq(roman_number)
        end
      end

      describe "self.from_roman(#{roman_number})" do
        it "returns its integer value (#{index + 1})" do
          expect(Integer.from_roman(roman_number)).to eq(index + 1)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
