# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe User, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user) }

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer_level_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[settings swimmer coach_level_type managed_affiliations]
      )
      #-- ----------------------------------------------------------------------
      #++

      it 'is valid' do
        expect(subject).to be_a(User).and be_valid
      end
      it 'is has a #name' do
        expect(subject).to respond_to(:name)
        expect(subject.name).to be_present
      end
      it 'is has an #email' do
        expect(subject).to respond_to(:email)
        expect(subject.email).to be_present
      end
    end

    # Any user settings should have the :prefs key:
    describe '#settings' do
      subject { GogglesDb::User.limit(20).sample }
      it 'includes the :prefs key' do
        expect(subject.settings(:prefs)).to be_a(RailsSettings::SettingObject)
        expect(subject.settings(:prefs).value).to be_an(Hash)
      end
    end

    describe '#swimmer' do
      let(:swimmer) { FactoryBot.create(:swimmer) }
      subject { FactoryBot.create(:user, swimmer: swimmer) }

      before(:each) do
        expect(swimmer).to be_a(Swimmer).and be_valid
        expect(subject).to be_a(User).and be_valid
      end

      context 'when a User is associated to a Swimmer' do
        it 'does not yield errors' do
          expect { subject.swimmer }.not_to raise_error
        end
        it 'is the associated Swimmer' do
          expect(subject.swimmer).to eq(swimmer)
        end
        it 'is maps correctly the inverse association' do
          expect(subject.swimmer.associated_user).to eq(subject)
          expect(swimmer.associated_user).to eq(subject)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.from_omniauth' do
      # User found, confirmed & ok:
      context 'for an existing, confirmed user with valid auth.info data,' do
        # TODO
      end

      # User found, unconfirmed but ok:
      context 'for an existing, unconfirmed user with valid auth.info data,' do
        # TODO
      end

      # User found, wrong response:
      context 'for an existing user with invalid or empty auth.info data,' do
        # TODO
      end

      # New User, ok:
      context 'for a new user with valid auth.info data,' do
        # TODO
      end

      # New User, wrong response:
      context 'for a new user with invalid or empty auth.info data,' do
        # TODO
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
