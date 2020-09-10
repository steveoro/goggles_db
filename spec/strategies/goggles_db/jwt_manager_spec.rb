# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe JwtManager, type: :strategy do
    let(:fixture_key)     { "fake_base_key #{rand * 10_000}" }
    let(:fixture_user_id) { (rand * 10_000).to_i }
    let(:fixture_text)    { 'whatever!' }
    let(:fixture_key)     { 'fake_base_key' }
    let(:fixture_payload) { { my_user_id: fixture_user_id, other_stuff: fixture_text } }

    context 'when using valid construction parameters,' do
      # (Testing the instance methods will automaticall test also the corresponding class implementation)
      subject { JwtManager.new(fixture_key, 1.hour) }

      it_behaves_like(
        'responding to a list of class methods',
        %i[encode decode]
      )

      it 'creates a new instance' do
        expect(subject).to be_a(JwtManager)
      end

      let(:encoded_jwt)     { subject.encode(fixture_payload) }
      let(:decoded_jwt)     { subject.decode(encoded_jwt) }

      describe '#encode' do
        it 'returns a String' do
          expect(encoded_jwt).to be_a(String).and be_present
        end
        it 'obfuscates the data keys' do
          expect(encoded_jwt).not_to include('my_user_id')
          expect(encoded_jwt).not_to include('other_stuff')
        end
      end

      describe '#decode' do
        context 'when the JWT contains valid data,' do
          it 'returns a kind of Hash with the expected data keys' do
            expect(decoded_jwt).to be_a_kind_of(Hash).and be_present
          end
          it 'has the expected data keys' do
            expect(decoded_jwt).to respond_to(:keys)
            expect(decoded_jwt.keys).to match_array(%w[my_user_id other_stuff])
          end
          it 'matches the payload' do
            expect(decoded_jwt['my_user_id']).to eq(fixture_user_id)
            expect(decoded_jwt['other_stuff']).to eq(fixture_text)
          end
        end

        context 'when the JWT is invalid,' do
          it 'is nil' do
            expect(subject.decode('surely not a valid JWT')).to be nil
          end
        end
      end
    end
  end
end
