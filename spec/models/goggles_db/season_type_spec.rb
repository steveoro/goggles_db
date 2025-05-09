# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe SeasonType do
    it_behaves_like(
      'responding to a list of methods',
      %i[masters? code_to_instance_var_name]
    )

    %w[mas_fin mas_csi mas_uisp ago_fin ago_csi ago_uisp mas_len mas_fina].each do |word|
      # Redefine the subject on a specific instance in order to use the shared_examples:
      subject { described_class.send(word) }

      it_behaves_like(
        'having one or more required associations',
        %i[federation_type]
      )
      it_behaves_like('responding to a list of methods', ["#{word}?"])

      it 'has a valid FederationType' do
        expect(subject.federation_type).to be_a(FederationType).and be_valid
      end

      it 'has a #code' do
        expect(subject).to respond_to(:code)
        expect(subject.code).to be_present
      end

      describe "self.#{word}" do
        it 'is a valid instance of the same class' do
          expect(subject).to be_a(described_class).and be_valid
        end

        it "has a corresponding (true, for having the same code) ##{word}? helper method" do
          # Not using the subject here on purpose as the double send() forces subject instantiation:
          expect(described_class.send(word).send(:"#{word}?")).to be true
        end
      end

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Scopes & virtual scopes:
    describe 'self.all_masters' do
      it 'is an array of Masters-only Season types' do
        expect(subject.class.all_masters).to be_an(Array)
        expect(subject.class.all_masters).to all(be_masters)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.validate_cached_rows' do
      it 'does not raise any errors' do
        expect { described_class.validate_cached_rows }.not_to raise_error
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
