# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe StrokeType do
    %w[freestyle butterfly backstroke breaststroke intermixed
       exe_starting exe_lapturns exe_power exe_generic rel_intermixed].each do |word|
      describe "self.#{word}" do
        subject { described_class.send(word) }

        it_behaves_like('Localizable') # includes checking for #code
        it_behaves_like('ApplicationRecord shared interface')

        it 'responds to #eventable?' do
          expect(subject).to respond_to(:eventable?)
        end

        it "has a corresponding (true, for having the same code) ##{word}? helper method" do
          expect(subject.send(:"#{word}?")).to be true
        end
      end
    end

    describe 'self.validate_cached_rows' do
      it 'does not raise any errors' do
        expect { described_class.validate_cached_rows }.not_to raise_error
      end
    end

    # Scopes & "virtual" scopes:
    describe 'self.all_eventable' do
      it 'contains only eventable stroke types' do
        expect(subject.class.all_eventable).to all(be_eventable)
      end
    end
  end
end
