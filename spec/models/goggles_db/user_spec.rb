# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe User do
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

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it 'has a #name' do
        expect(subject).to respond_to(:name)
        expect(subject.name).to be_present
      end

      it 'is has an #email' do
        expect(subject).to respond_to(:email)
        expect(subject.email).to be_present
      end

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'base validations: uniqueness' do
      let(:existing_user) { described_class.first(50).sample }

      before { expect(existing_user).to be_a(described_class).and be_valid }

      context 'an instance with an already existing name' do
        subject { FactoryBot.build(:user, name: existing_user.name) }

        it 'is not valid' do
          expect(subject).not_to be_valid
        end
      end

      context 'an instance with an already existing email' do
        subject { FactoryBot.build(:user, email: existing_user.email) }

        it 'is not valid' do
          expect(subject).not_to be_valid
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'user deletion: before_destroy' do
      context 'when the user has any association bound by foreign key,' do
        let(:deletable_user) { FactoryBot.create(:user) }
        let(:fixture_reservation) { FactoryBot.create(:meeting_reservation, user: deletable_user) }
        let(:fixture_managed_affiliation) { FactoryBot.create(:managed_affiliation, manager: deletable_user) }
        let(:fixture_workshop) { FactoryBot.create(:user_workshop, user: deletable_user) }
        let(:fixture_result) { FactoryBot.create(:user_result, user: deletable_user, user_workshop: fixture_workshop) }

        before do
          # Verify domain:
          expect(deletable_user).to be_a(described_class).and be_valid
          expect(fixture_reservation).to be_a(MeetingReservation).and be_valid
          expect(fixture_managed_affiliation).to be_a(ManagedAffiliation).and be_valid
          expect(fixture_workshop).to be_a(UserWorkshop).and be_valid
          expect(fixture_result).to be_a(UserResult).and be_valid
          deletable_user.destroy
        end

        it 'destroys the user' do
          expect(deletable_user).to be_destroyed
        end

        it 'destroys also all the associated MeetingReservation(s)' do
          expect { fixture_reservation.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'destroys also all the associated ManagedAffiliation(s)' do
          expect { fixture_managed_affiliation.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'moves any UserWorkshop association to the placeholder user' do
          fixture_workshop.reload
          expect(fixture_workshop.user_id).to eq(described_class::PLACEHOLDER_ID)
        end

        it 'moves any UserResult association to the placeholder user' do
          fixture_result.reload
          expect(fixture_result.user_id).to eq(described_class::PLACEHOLDER_ID)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'swimmer association: after_create' do
      context 'when the user has an auto-match with an available swimmer' do
        let(:existing_swimmer) { FactoryBot.create(:swimmer) }
        let(:fixture_user) do
          FactoryBot.build(
            :user,
            first_name: existing_swimmer.first_name,
            last_name: existing_swimmer.last_name,
            year_of_birth: existing_swimmer.year_of_birth,
            description: existing_swimmer.complete_name,
            swimmer_id: nil
          )
        end

        before do
          # Verify domain:
          expect(existing_swimmer).to be_a(Swimmer).and be_valid
          expect(fixture_user).to be_a(described_class).and be_valid
          # Create the user, then verify after create:
          fixture_user.save!
        end

        it 'binds the user with the swimmer updating both the swimmer_id & its associated_user_id' do
          fixture_user.reload
          # Need to reload the row updated indipendently by the after_action filter:
          existing_swimmer.reload
          expect(fixture_user.swimmer_id).to eq(existing_swimmer.id)
          expect(existing_swimmer.associated_user_id).to eq(fixture_user.id)
        end
      end
    end

    context 'swimmer association: after_safe' do
      context 'when the user has changed the swimmer association' do
        let(:fixture_swimmer) { FactoryBot.create(:swimmer) }
        let(:fixture_user) do
          FactoryBot.create(
            :user,
            first_name: fixture_swimmer.first_name,
            last_name: fixture_swimmer.last_name,
            year_of_birth: fixture_swimmer.year_of_birth,
            description: fixture_swimmer.complete_name,
            swimmer_id: fixture_swimmer.id
          )
        end
        let(:another_swimmer) { Swimmer.last(50).sample }

        before do
          # Verify domain:
          expect(fixture_swimmer).to be_a(Swimmer).and be_valid
          expect(fixture_user).to be_a(described_class).and be_valid
          expect(another_swimmer).to be_a(Swimmer).and be_valid
          expect(fixture_user.swimmer_id).to eq(fixture_swimmer.id)
          # Reload the row updated indipendently:
          fixture_swimmer.reload
          expect(fixture_swimmer.associated_user_id).to eq(fixture_user.id)
          # Edit association just on one side, then verify after save:
          fixture_user.swimmer_id = another_swimmer.id
          fixture_user.save!
        end

        it 'binds the user with swimmer updating both swimmer_id & associated_user_id' do
          expect(fixture_user.swimmer_id).to eq(another_swimmer.id)
          # Reload the row updated indipendently:
          another_swimmer.reload
          expect(another_swimmer.associated_user_id).to eq(fixture_user.id)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Any user settings should have the :prefs key:
    describe '#settings' do
      subject { described_class.limit(20).sample }

      it 'includes the :prefs key' do
        expect(subject.settings(:prefs)).to be_a(RailsSettings::SettingObject)
        expect(subject.settings(:prefs).value).to be_an(Hash)
      end
    end

    describe '#swimmer' do
      subject do
        FactoryBot.create(
          :user,
          first_name: swimmer.first_name,
          last_name: swimmer.last_name,
          year_of_birth: swimmer.year_of_birth,
          swimmer:
        )
      end

      let(:swimmer) { FactoryBot.create(:swimmer) }

      before do
        expect(swimmer).to be_a(Swimmer).and be_valid
        expect(subject).to be_a(described_class).and be_valid
      end

      context 'when a User is associated to a Swimmer,' do
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

      before do
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
      context 'with an existing, already confirmed user providing valid auth data,' do
        subject { described_class.from_omniauth(auth_response) }

        let(:confirmed_user) { described_class.where.not(confirmed_at: nil).limit(50).sample }
        let(:auth_response) { valid_auth(provider, uid, confirmed_user) }

        before do
          expect(confirmed_user).to be_a(described_class).and be_valid
          expect(confirmed_user).to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(confirmed_user.email)
        end

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
      context 'with an existing, unconfirmed user providing valid auth data,' do
        subject { described_class.from_omniauth(auth_response) }

        let(:unconfirmed_user) do
          user = FactoryBot.create(:user)
          user.skip_confirmation_notification!
          user.update!(confirmed_at: nil)
          user.reload
        end
        let(:auth_response) { valid_auth(provider, uid, unconfirmed_user) }

        before do
          expect(unconfirmed_user).to be_a(described_class).and be_valid
          expect(unconfirmed_user).not_to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(unconfirmed_user.email)
        end

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

      # new User Email but existing (conflicting) User name found => error:
      context 'with a new Email but with an already existing user name,' do
        subject { described_class.from_omniauth(auth_response) }

        let(:another_user) { described_class.where.not(confirmed_at: nil).first(50).sample }
        let(:conflicting_user) { FactoryBot.build(:user, name: another_user.name, email: FFaker::Internet.safe_email) }
        let(:auth_response) { valid_auth(provider, uid, conflicting_user) }

        before do
          expect(another_user).to be_a(described_class).and be_valid
          expect(conflicting_user).to be_a(described_class)
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['name']).to eq(another_user.name)
          expect(auth_response.info['email']).to eq(conflicting_user.email)
        end

        it 'includes the user name from the auth response' do
          expect(subject.name).to eq(conflicting_user.name)
          expect(subject.first_name).to eq(conflicting_user.first_name)
          expect(subject.last_name).to eq(conflicting_user.last_name)
        end

        it 'includes the user email from the auth response' do
          expect(subject.email).to eq(conflicting_user.email)
        end

        it 'is NOT persisted' do
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

      # New User, ok:
      context 'with a new user providing valid auth data,' do
        subject { described_class.from_omniauth(auth_response) }

        let(:new_user) { FactoryBot.build(:user, first_name: "#{FFaker::Name.first_name} Stewie1", confirmed_at: nil) }
        let(:auth_response) { valid_auth(provider, uid, new_user) }
        # Create an already existing matching swiming for the new user:
        let(:existing_swimmer) do
          FactoryBot.create(
            :swimmer,
            first_name: new_user.first_name,
            last_name: new_user.last_name,
            year_of_birth: new_user.year_of_birth,
            complete_name: new_user.description,
            associated_user_id: nil # <-- expected to be set by the #from_omniauth method
          )
        end

        before do
          expect(new_user).to be_a(described_class).and be_valid
          expect(new_user).not_to be_confirmed
          expect(auth_response).to be_an(OmniAuth::AuthHash).and be_valid
          expect(auth_response.info['email']).to eq(new_user.email)
          expect(existing_swimmer).to be_a(Swimmer).and be_valid
          expect(new_user.matching_swimmers).not_to be_empty
        end

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

        # [Steve A.] Note that given we are using random names, we cannot assert effectively that:
        #            subject.matching_swimmers.first.id == existing_swimmer.id
        context 'when there\'s an existing, matching (and available) swimmer,' do
          before do
            # Reload the row updated indipendently:
            subject.reload
          end

          it 'is automatically associated to the first matching swimmer by default' do
            expect(subject.swimmer_id).to eq(subject.matching_swimmers.first.id)
          end

          it 'binds automatically also the associated swimmer to the user' do
            expect(subject.id).to be_positive
            expect(subject.swimmer.associated_user_id).to eq(subject.id)
          end
        end
      end

      # Wrong response/scope parameter: nil
      context 'when providing nil,' do
        subject { described_class.from_omniauth(nil) }

        it 'is an unfiltered ActiveRecord::Relation' do
          expect(subject).not_to respond_to(:errors)
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      # Wrong response/scope parameter: other object than OAuth
      context 'when returning an empty string,' do
        subject { described_class.from_omniauth('') }

        it 'is an unfiltered ActiveRecord::Relation' do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context 'when returning an empty hash,' do
        subject { described_class.from_omniauth({}) }

        it 'is an unfiltered ActiveRecord::Relation' do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#matching_swimmers' do
      let(:fixture_swimmer) { FactoryBot.create(:swimmer) }
      let(:fake_domains) { %w[fake.example.com fake.example.org fake.example.net] }
      # Same year of birth and equal name:

      context 'when the user has a matching swimmer' do
        subject { fixture_user.matching_swimmers }

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

        before do
          expect(fixture_user).to be_a(described_class).and be_valid
          expect(fixture_swimmer).to be_a(Swimmer).and be_valid
        end

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
        subject { fixture_user.matching_swimmers }

        let(:fixture_swimmer) { FactoryBot.create(:swimmer) }
        let(:fixture_user) do
          FactoryBot.create(
            :user,
            first_name: fixture_swimmer.first_name,
            last_name: fixture_swimmer.last_name,
            year_of_birth: 1900,
            description: fixture_swimmer.complete_name,
            swimmer_id: nil
          )
        end

        before do
          expect(fixture_user).to be_a(described_class).and be_valid
          expect(fixture_swimmer).to be_a(Swimmer).and be_valid
          expect(fixture_user.year_of_birth != fixture_swimmer.year_of_birth).to be true
        end

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
          subject { fixture_user1.matching_swimmers }

          let(:fixture_swimmer1) do
            FactoryBot.create(
              :swimmer,
              first_name: names_hash[:swimmer_first],
              last_name: names_hash[:swimmer_last],
              complete_name: "#{names_hash[:swimmer_last].upcase} #{names_hash[:swimmer_first].upcase}"
            )
          end
          let(:fixture_user1) do
            email = "#{names_hash[:user_last].split.first}.#{names_hash[:user_first].split.first}#{(rand * 100_000).to_i}@#{fake_domains.sample}"
            FactoryBot.create(
              :user,
              first_name: names_hash[:user_first],
              last_name: names_hash[:user_last],
              description: "#{names_hash[:user_last]} #{names_hash[:user_first]}",
              email:,
              year_of_birth: fixture_swimmer1.year_of_birth
            )
          end

          before do
            expect(fixture_user1).to be_a(described_class).and be_valid
            expect(fixture_swimmer1).to be_a(Swimmer).and be_valid
          end

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
    #-- -----------------------------------------------------------------------
    #++

    shared_examples_for '#associate_to_swimmer! skipping updates' do |use_override|
      # (With or without 'swimmer_override')
      let(:swimmer_override) { use_override ? fixture_swimmer : nil }

      it 'doesn\'t change the User\'s swimmer_id (as well as the row itself)' do
        expect { fixture_user.associate_to_swimmer!(swimmer_override) }.not_to change(
          fixture_user, :swimmer_id
        )
      end
      # Skip whole test if override is not used:

      if use_override
        it 'doesn\'t change the Swimmer\'s associated_user_id (as well as the row itself)' do
          expect { fixture_user.associate_to_swimmer!(swimmer_override) }.not_to change(
            swimmer_override, :associated_user_id
          )
        end
      end
    end

    # (Subject method is invoked in shared examples)
    shared_examples_for '#associate_to_swimmer! returning nil (unpersisted, NO update)' do |use_override|
      # (With or without 'swimmer_override')
      let(:swimmer_override) { use_override ? fixture_swimmer : nil }

      it 'doesn\'t save the user instance' do
        fixture_user.associate_to_swimmer!(swimmer_override)
        expect(fixture_user).not_to be_persisted
      end

      it 'returns nil' do
        expect(fixture_user.associate_to_swimmer!(swimmer_override)).to be_nil
      end

      it_behaves_like('#associate_to_swimmer! skipping updates', use_override)
    end

    shared_examples_for '#associate_to_swimmer! successfully updates' do |use_override|
      # (With or without 'swimmer_override')
      let(:swimmer_override) { use_override ? fixture_swimmer : nil }

      it 'saves the user instance' do
        expect(fixture_user).to be_persisted
      end

      it 'updates the User\'s swimmer_id' do
        expect(fixture_user.swimmer_id).to eq(fixture_swimmer.id)
      end

      it 'updates the Swimmer\'s associated_user_id' do
        # Reload the row updated indipendently:
        fixture_swimmer.reload
        expect(fixture_swimmer.associated_user_id).to eq(fixture_user.id)
      end

      it 'returns the swimmer associated to the user' do
        expect(fixture_user.associate_to_swimmer!(swimmer_override)).to eq(fixture_swimmer)
      end
    end
    #-- -----------------------------------------------------------------------
    #++

    describe '#associate_to_swimmer!' do
      let(:fixture_swimmer) { FactoryBot.create(:swimmer) }

      context 'without a swimmer override parameter,' do
        # ** NO UPDATE: new user, invalid **
        context 'when the user instance is new and some required fields are missing' do
          let(:fixture_user) { described_class.new }

          before do
            expect(fixture_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_user).to be_a(described_class)
          end

          # (Subject method is invoked in shared examples)
          it_behaves_like('#associate_to_swimmer! returning nil (unpersisted, NO update)', false)
        end

        # ** NO UPDATE: new user, valid but "unfilterable" **
        context 'when the user instance is new but doesn\'t have a last_name (no filtering possible)' do
          let(:fixture_user) do
            FactoryBot.build(
              :user,
              first_name: fixture_swimmer.first_name,
              last_name: nil,
              year_of_birth: fixture_swimmer.year_of_birth,
              description: fixture_swimmer.complete_name,
              swimmer_id: nil
            )
          end

          before do
            expect(fixture_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_user).to be_a(described_class).and be_valid
          end

          # (Subject method is invoked in shared examples)
          it_behaves_like('#associate_to_swimmer! returning nil (unpersisted, NO update)', false)
        end

        context 'when the user has indeed a matching swimmer' do
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

          before do
            expect(fixture_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_user).to be_a(described_class).and be_valid
          end

          # ** UPDATE: existing user, swimmer is free **
          context 'and the swimmer is available,' do
            before do
              # We don't care about the user's association over here (could be anything)
              # as it must be overwritten anyway
              fixture_swimmer.reload.associated_user_id = nil
              fixture_swimmer.save!
              fixture_user.associate_to_swimmer!
            end

            it_behaves_like('#associate_to_swimmer! successfully updates', false)
          end

          # ** NO UPDATE: existing user, swimmer NOT free **
          context 'and the swimmer is NOT available,' do
            let(:another_user) { described_class.first(20).sample }

            before do
              fixture_swimmer.reload.associated_user_id = another_user.id
              fixture_swimmer.save!
            end

            # (Subject method is invoked in shared examples)
            it_behaves_like('#associate_to_swimmer! skipping updates', nil)

            it 'returns the matching swimmer anyway' do
              expect(fixture_user.associate_to_swimmer!).to eq(fixture_swimmer)
            end
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      context 'with a matching_swimmer override parameter,' do
        # ** NO UPDATE: new user, invalid + swimmer override **
        context 'when the user instance is new and some required fields are missing (no filtering possible)' do
          let(:fixture_user) { described_class.new }

          before do
            expect(fixture_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_user).to be_a(described_class)
          end

          # (Subject method is invoked in shared examples)
          it_behaves_like('#associate_to_swimmer! returning nil (unpersisted, NO update)', true)
        end

        context 'when the user instance is new and doesn\'t have a last_name (no filtering possible)' do
          let(:fixture_user) do
            FactoryBot.build(
              :user,
              first_name: fixture_swimmer.first_name,
              last_name: nil,
              year_of_birth: fixture_swimmer.year_of_birth,
              description: fixture_swimmer.complete_name,
              swimmer_id: nil
            )
          end

          before do
            expect(fixture_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_user).to be_a(described_class).and be_valid
          end

          # ** UPDATE: new user, valid + swimmer override free **
          context 'and the specified swimmer is available,' do
            before do
              # We don't care about the user's association over here (could be anything)
              # as it will be overwritten anyway
              fixture_swimmer.reload.associated_user_id = nil
              fixture_swimmer.save!
              fixture_user.associate_to_swimmer!(fixture_swimmer)
            end

            it_behaves_like('#associate_to_swimmer! successfully updates', true)
          end

          # ** NO UPDATE: new user, valid + swimmer override NOT free **
          context 'and the specified swimmer is NOT available,' do
            let(:another_user) { described_class.first(20).sample }

            before do
              fixture_swimmer.reload.associated_user_id = another_user.id
              fixture_swimmer.save!
            end

            # (Subject method is invoked in shared examples)
            it_behaves_like('#associate_to_swimmer! skipping updates', true)
            it 'returns the specified swimmer anyway' do
              expect(fixture_user.associate_to_swimmer!(fixture_swimmer)).to eq(fixture_swimmer)
            end
          end
        end

        # ** UPDATE, with OVERRIDE **
        context 'when the user has indeed a matching swimmer' do
          let(:another_swimmer) { Swimmer.first(50).sample }
          let(:fixture_user) do
            FactoryBot.create(
              :user,
              first_name: another_swimmer.first_name,
              last_name: another_swimmer.last_name,
              year_of_birth: another_swimmer.year_of_birth,
              description: another_swimmer.complete_name,
              swimmer_id: nil
            )
          end

          before do
            expect(another_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_swimmer).to be_a(Swimmer).and be_valid
            expect(fixture_user).to be_a(described_class).and be_valid
          end

          # ** UPDATE: valid user + swimmer override free **
          context 'and the specified swimmer is available,' do
            before do
              # We don't care about the user's association over here (could be anything)
              # as it will be overwritten anyway
              fixture_swimmer.reload.associated_user_id = nil
              fixture_swimmer.save!
              fixture_user.associate_to_swimmer!(fixture_swimmer)
            end

            it_behaves_like('#associate_to_swimmer! successfully updates', true)
          end

          # ** NO UPDATE: new user, valid + swimmer override NOT free **
          context 'and the specified swimmer is NOT available,' do
            let(:another_user) { described_class.first(20).sample }

            before do
              fixture_swimmer.reload.associated_user_id = another_user.id
              fixture_swimmer.save!
            end

            # (Subject method is invoked in shared examples)
            it_behaves_like('#associate_to_swimmer! skipping updates', true)
            it 'returns the specified swimmer anyway' do
              expect(fixture_user.associate_to_swimmer!(fixture_swimmer)).to eq(fixture_swimmer)
            end
          end
        end
      end
    end
    #-- -----------------------------------------------------------------------
    #++
  end
end
