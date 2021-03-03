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
      let(:provider) { %w[facebook github google_oauth2 twitter].sample }
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
        let(:existing_swimmer) do
          FactoryBot.create(
            :swimmer,
            first_name: new_user.first_name,
            last_name: new_user.last_name,
            year_of_birth: new_user.year_of_birth,
            complete_name: new_user.description,
            associated_user_id: nil
          )
        end

        before(:each) do
          expect(new_user).to be_a(User).and be_valid
          expect(new_user).not_to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(new_user.email)
          expect(existing_swimmer).to be_a(Swimmer).and be_valid
          expect(new_user.matching_swimmers).not_to be_empty
        end

        subject { User.from_omniauth(auth_response) }

        it 'matches the auth data' do
          expect(subject.email).to eq(auth_response.info['email'])
          expect(subject.name).to eq(auth_response.info['name'])
          expect(subject.first_name).to eq(auth_response.info['first_name'])
          expect(subject.last_name).to eq(auth_response.info['last_name'])
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
        it 'has an already associated swimmer by default (if there\'s a match)' do
          expect(subject.reload.swimmer_id).to eq(existing_swimmer.id)
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

    let(:fixture_swimmer) { FactoryBot.create(:swimmer) }
    let(:fixture_user) do
      FactoryBot.create(
        :user,
        first_name: fixture_swimmer.first_name,
        last_name: fixture_swimmer.last_name,
        year_of_birth: fixture_swimmer.year_of_birth,
        description: fixture_swimmer.complete_name,
        swimmer_id: nil
      )
    end

    describe '#matching_swimmers' do
      # Same year of birth and equal name:
      context 'when the user has a matching swimmer' do
        before(:each) do
          expect(fixture_user).to be_a(User).and be_valid
          expect(fixture_swimmer).to be_a(Swimmer).and be_valid
        end
        subject { fixture_user.matching_swimmers }

        it 'is a non-empty ActiveRecord::Relation' do
          expect(subject).to be_a(ActiveRecord::Relation)
          expect(subject).not_to be_empty
        end
        it 'includes the matching swimmer' do
          expect(fixture_user.matching_swimmers).to include(fixture_swimmer)
        end
      end

      # Same name but no user's year of birth:
      context 'when the user has a matching swimmer but no birth date' do
        before(:each) do
          expect(fixture_user).to be_a(User).and be_valid
          expect(fixture_swimmer).to be_a(Swimmer).and be_valid
          fixture_user.update!(year_of_birth: 1900)
          expect(fixture_user.year_of_birth != fixture_swimmer.year_of_birth).to be true
        end
        subject { fixture_user.matching_swimmers }

        it 'is a non-empty ActiveRecord::Relation' do
          expect(subject).to be_a(ActiveRecord::Relation)
          expect(subject).not_to be_empty
        end
        it 'includes the matching swimmer' do
          expect(fixture_user.matching_swimmers).to include(fixture_swimmer)
        end
      end

      # Same year of birth but slightly-different name:
      [
        { user_first: 'Ido', user_last: 'Orlandini', swimmer_first: 'Ido Pieraldo', swimmer_last: 'Orlandini' },
        { user_first: 'Stefano', user_last: 'Alloro', swimmer_first: 'Stefano Luca', swimmer_last: 'Alloro' },
        { user_first: 'Marco Paolino', user_last: 'Gilbertazzi', swimmer_first: 'PAOLINO', swimmer_last: 'GILBERTAZZI' },
        { user_first: 'Marco Pino', user_last: 'Gilbertazzi', swimmer_first: 'Marco', swimmer_last: 'GILBERTAZZI' },
        { user_first: 'Lino Gino Rino', user_last: 'Rossi', swimmer_first: 'GINO', swimmer_last: 'Rossi' },
        { user_first: 'Guendalina Veronica', user_last: 'Mazzanti Vien Dal Mare', swimmer_first: 'Veronica', swimmer_last: 'Mazzanti' },
        { user_first: 'Paola Maria', user_last: 'Mazzanti Vien Dalmare', swimmer_first: 'Paola Maria Lucia', swimmer_last: 'Viendalmare' }
      ].each do |names_hash|
        context 'when the user has a partially-matching swimmer name' do
          let(:fixture_swimmer1) do
            FactoryBot.create(
              :swimmer,
              first_name: names_hash[:swimmer_first],
              last_name: names_hash[:swimmer_last],
              complete_name: "#{names_hash[:swimmer_last].upcase} #{names_hash[:swimmer_first].upcase}"
            )
          end
          let(:fixture_user1) do
            email = "#{names_hash[:user_last].split.first}.#{names_hash[:user_first].split.first}" +
                    "#{(rand * 100_000).to_i}@#{%w[fake.example.com fake.example.org fake.example.net].sample}"
            FactoryBot.create(
              :user,
              first_name: names_hash[:user_first],
              last_name: names_hash[:user_last],
              description: "#{names_hash[:user_last]} #{names_hash[:user_first]}",
              email: email,
              year_of_birth: fixture_swimmer1.year_of_birth
            )
          end
          before(:each) do
            expect(fixture_user1).to be_a(User).and be_valid
            expect(fixture_swimmer1).to be_a(Swimmer).and be_valid
          end
          subject { fixture_user1.matching_swimmers }

          it 'is a non-empty ActiveRecord::Relation' do
            expect(subject).to be_a(ActiveRecord::Relation)
            expect(subject).not_to be_empty
          end
          it 'includes the matching swimmer' do
            expect(fixture_user1.matching_swimmers).to include(fixture_swimmer1)
          end
        end
      end
    end

    describe '#associate_to_swimmer!' do
      context 'when the user instance in new (and names are empty)' do
        it 'returns nil' do
          expect(User.new.associate_to_swimmer!).to be nil
        end
        it 'does not change the swimmer_id field' do
          User.new.associate_to_swimmer!
          expect(User.new.swimmer_id).to be_blank
        end
      end

      context 'when the user has indeed a matching swimmer' do
        before(:each) do
          expect(fixture_user).to be_a(User).and be_valid
          expect(fixture_swimmer).to be_a(Swimmer).and be_valid
        end

        context 'and the swimmer is not yet associated,' do
          before(:each) do
            fixture_swimmer.associated_user_id = nil
            fixture_swimmer.save!
          end
          subject { fixture_user.associate_to_swimmer! }

          it 'sets the swimmer_id field' do
            fixture_user.associate_to_swimmer!
            expect(fixture_user.swimmer_id).to eq(fixture_swimmer.id)
          end
          it 'changes the record' do
            fixture_user.associate_to_swimmer!
            expect(fixture_user).to be_changed
          end
          it 'returns the first swimmer found' do
            expect(fixture_user.associate_to_swimmer!).to eq(fixture_swimmer)
          end
        end

        context 'and the swimmer is already associated,' do
          before(:each) do
            fixture_swimmer.associated_user_id = fixture_user.id
            fixture_swimmer.save!
          end
          it 'does not change the swimmer_id field' do
            fixture_user.associate_to_swimmer!
            expect(fixture_user.swimmer_id).to be_blank
            expect(fixture_user).not_to be_changed
          end
          it 'returns the first swimmer found' do
            expect(fixture_user.associate_to_swimmer!).to eq(fixture_swimmer)
          end
        end
      end
    end
  end
end
