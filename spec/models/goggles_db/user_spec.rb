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

    require 'omniauth/auth_hash'

    # Filtering scopes:
    describe 'self.from_omniauth' do
      let(:provider) { %w[facebook github google twitter].sample }
      let(:uid) { FFaker::SSN.ssn }

      before(:each) do
        expect(provider).to be_a(String).and be_present
        expect(uid).to be_a(String).and be_present
      end

      # Helper for defining a valid OAuth token given user credentials
      # Returns an OmniAuth::AuthHash
      def valid_auth(provider, uid, user)
        auth = OmniAuth::AuthHash.new
        auth.regular_writer('provider', provider)
        auth.regular_writer('uid', uid)
        auth.regular_writer('info', {
                              email: user.email,
                              name: user.name,
                              first_name: user.first_name,
                              last_name: user.last_name,
                              verified: true
                            })
        auth.regular_writer('credentials', {
                              token: 'ABCDEFGHIJKLMNO', # OAuth 2.0 access_token (least/minimal info to be stored)
                              expires_at: 1_321_747_205, # decode from Unix timestamp
                              expires: true # (always true)
                            })
        auth
      end

      # User found, confirmed & ok:
      context 'for an existing, already confirmed user providing valid auth data,' do
        let(:confirmed_user) { User.where('confirmed_at is not null').limit(50).sample }
        let(:auth_response) { valid_auth(provider, uid, confirmed_user) }

        before(:each) do
          expect(confirmed_user).to be_a(User).and be_valid
          expect(confirmed_user).to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(confirmed_user.email)
        end

        subject { User.from_omniauth(auth_response) }

        it 'is the expected User instance' do
          expect(subject).to eq(confirmed_user)
        end
        it 'is persisted' do
          expect(subject).to be_persisted
        end
        it 'is confirmed' do
          expect(subject).to be_confirmed
        end
        it 'has updated the provider & uid fields' do
          expect(subject.provider).to eq(auth_response.provider)
          expect(subject.provider).to eq(provider)
          expect(subject.uid).to eq(auth_response.uid)
          expect(subject.uid).to eq(uid)
        end
      end

      # User found, unconfirmed but ok:
      context 'for an existing, unconfirmed user providing valid auth data,' do
        let(:unconfirmed_user) do
          user = FactoryBot.create(:user)
          user.skip_confirmation_notification!
          user.update!(confirmed_at: nil)
          user.reload
        end
        let(:auth_response) { valid_auth(provider, uid, unconfirmed_user) }

        before(:each) do
          expect(unconfirmed_user).to be_a(User).and be_valid
          expect(unconfirmed_user).not_to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(unconfirmed_user.email)
        end

        subject { User.from_omniauth(auth_response) }

        it 'is the expected User instance' do
          expect(subject).to eq(unconfirmed_user)
        end
        it 'is persisted' do
          expect(subject).to be_persisted
        end
        it 'is confirmed' do
          expect(subject).to be_confirmed
        end
        it 'has updated the provider & uid fields' do
          expect(subject.provider).to eq(auth_response.provider)
          expect(subject.provider).to eq(provider)
          expect(subject.uid).to eq(auth_response.uid)
          expect(subject.uid).to eq(uid)
        end
      end

      # New User, ok:
      context 'for a new user providing valid auth data,' do
        let(:new_user) { FactoryBot.build(:user, confirmed_at: nil) }
        let(:auth_response) { valid_auth(provider, uid, new_user) }

        before(:each) do
          expect(new_user).to be_a(User).and be_valid
          expect(new_user).not_to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(new_user.email)
        end

        subject { User.from_omniauth(auth_response) }

        it 'matches the auth data' do
          expect(subject.email).to eq(auth_response.info['email'])
          expect(subject.name).to eq(auth_response.info['name'])
          expect(subject.first_name).to eq(auth_response.info['first_name'])
          expect(subject.last_name).to eq(auth_response.info['last_name'])
        end
        it 'is not yet persisted' do
          expect(subject).not_to be_persisted
        end
        it 'is confirmed' do
          expect(subject).to be_confirmed
        end
        it 'has updated the provider & uid fields' do
          expect(subject.provider).to eq(auth_response.provider)
          expect(subject.provider).to eq(provider)
          expect(subject.uid).to eq(auth_response.uid)
          expect(subject.uid).to eq(uid)
        end
      end

      # Wrong response/scope parameter: nil
      context 'when providing nil,' do
        subject { User.from_omniauth(nil) }
        it 'is an unfiltered ActiveRecord::Relation' do
          expect(subject).not_to respond_to(:errors)
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      # Wrong response/scope parameter: other object than OAuth
      context 'when returning an empty string,' do
        subject { User.from_omniauth('') }
        it 'is an unfiltered ActiveRecord::Relation' do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end
      context 'when returning an empty hash,' do
        subject { User.from_omniauth({}) }
        it 'is an unfiltered ActiveRecord::Relation' do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
