# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe SeasonType, type: :model do
    %w[mas_fin mas_csi mas_uisp ago_fin ago_csi ago_uisp mas_len mas_fina].each do |word|
      # Redefine the subject on a specific instance in order to use the shared_examples:
      subject { described_class.send(word) }

      it_behaves_like(
        'having one or more required associations',
        %i[federation_type]
      )
      it_behaves_like(
        'responding to a list of methods',
        ["#{word}?"]
      )

      it 'has a valid FederationType' do
        expect(subject.federation_type).to be_a(FederationType).and be_valid
      end

      it 'is has a #code' do
        expect(subject).to respond_to(:code)
        expect(subject.code).to be_present
      end

      describe "self.#{word}" do
        it 'is a valid instance of the same class' do
          expect(described_class.send(word)).to be_a(described_class).and be_valid
        end

        it "has a corresponding (true, for having the same code) ##{word}? helper method" do
          expect(described_class.send(word).send("#{word}?")).to be true
        end
      end
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
        expect { subject.class.validate_cached_rows }.not_to raise_error
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      subject { existing_row.minimal_attributes }

      let(:existing_row) { described_class.limit(50).sample }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      it 'includes the federation_type association key' do
        expect(subject.keys).to include('federation_type')
      end
    end

    describe '#to_json' do
      subject { described_class.limit(50).sample }

      it 'is a String' do
        expect(subject.to_json).to be_a(String).and be_present
      end

      it 'can be parsed without errors' do
        expect { JSON.parse(subject.to_json) }.not_to raise_error
      end

      describe 'the 1st-level required association' do
        let(:json_hash) { JSON.parse(subject.to_json) }

        it 'contains the JSON details of its federation_type' do
          expect(json_hash['federation_type']).to be_an(Hash).and be_present
          expect(json_hash['federation_type']).to eq(
            JSON.parse(subject.federation_type.attributes.to_json)
          )
        end
      end
    end
  end
end
