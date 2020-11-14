# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe PoolType, type: :model do
    context 'any pre-seeded instance' do
      subject { PoolType.all.sample }

      it 'is valid' do
        expect(subject).to be_valid
      end

      it_behaves_like('Localizable')
    end

    %w[mt_25 mt_50 mt_33].each do |word|
      describe "self.#{word}" do
        it 'responds to #eventable?' do
          expect(subject.class.send(word)).to respond_to(:eventable?)
        end
        it 'is has a #code' do
          expect(subject.class.send(word).code).to be_present
        end
        it 'is a valid instance of the same class' do
          expect(subject.class.send(word)).to be_a(subject.class).and be_valid
        end
        it "has a corresponding (true, for having the same code) ##{word}? helper method" do
          expect(subject.class.send(word).send("#{word}?")).to be true
        end
      end
    end

    describe 'self.validate_cached_rows' do
      it 'does not raise any errors' do
        expect { subject.class.validate_cached_rows }.not_to raise_error
      end
    end

    # Scopes & "virtual" scopes:
    describe 'self.eventable' do
      it 'contains only eventable stroke types' do
        expect(subject.class.eventable).to all(be_eventable)
      end
    end
  end
end
