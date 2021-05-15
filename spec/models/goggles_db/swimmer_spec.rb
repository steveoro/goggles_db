# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe Swimmer, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:swimmer) }

      it_behaves_like(
        'having one or more required associations',
        %i[gender_type]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[
          associated_user male? female? intermixed? year_guessed?
          minimal_attributes to_json
        ]
      )
      #-- ----------------------------------------------------------------------
      #++

      it 'is valid' do
        expect(subject).to be_a(Swimmer).and be_valid
      end
      it 'has a valid GenderType' do
        expect(subject.gender_type).to be_a(GenderType).and be_valid
      end
      it 'is does not have an associated user yet' do
        expect(subject).to respond_to(:associated_user)
        expect(subject.associated_user).to be nil
      end
      it 'is has a #complete_name' do
        expect(subject).to respond_to(:complete_name)
        expect(subject.complete_name).to be_present
      end
      it 'is has a #year_of_birth' do
        expect(subject).to respond_to(:year_of_birth)
        expect(subject.year_of_birth).to be_present
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.for_name' do
      %w[john steve nicolas nicole serena].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', Swimmer, :for_name, %w[last_name first_name complete_name], filter_text)
      end
    end

    describe 'self.for_first_name' do
      %w[john steve nicolas nicole serena].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', Swimmer, :for_first_name, %w[first_name], filter_text)
      end
    end

    describe 'self.for_last_name' do
      %w[Alloro Jenkins Ligabue Smith].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', Swimmer, :for_last_name, %w[last_name], filter_text)
      end
    end

    describe 'self.for_complete_name' do
      ['Alloro Stefano', 'Jenkins', 'Ligabue', 'Smith'].each do |filter_text|
        it_behaves_like('filtering scope FULLTEXT for_...', Swimmer, :for_complete_name, %w[complete_name], filter_text)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      subject { FactoryBot.create(:swimmer).minimal_attributes }
      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[long_label associated_user gender_type].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(subject.keys).to include(member_name)
        end
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:swimmer) }

      # Required associations & members:
      %w[long_label].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(subject.to_json[member_name]).to be_present
        end
      end
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[gender_type]
      )
      it_behaves_like(
        '#to_json when called with unset optional associations',
        %w[associated_user]
      )

      # Optional associations:
      context 'when the entity contains other optional associations' do
        let(:fixture_user) { FactoryBot.create(:user) }
        subject            { FactoryBot.create(:swimmer, associated_user: fixture_user) }

        let(:json_hash) do
          expect(subject.associated_user).to be_a(User).and be_valid
          expect(subject.associated_user_id).to eq(fixture_user.id)
          JSON.parse(subject.to_json)
        end

        it_behaves_like(
          '#to_json when the entity contains other optional associations with',
          %w[associated_user]
        )
      end
    end
  end
end
