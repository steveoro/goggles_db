# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe TimingFinders::Factory, type: :strategy do
    it 'responds to self.for' do
      expect(TimingFinders::Factory).to respond_to(:for)
    end

    describe 'self.for' do
      context 'for an invalid parameter' do
        subject { TimingFinders::Factory.for(nil) }
        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
      context 'for an empty or unsupported EntryTimeType' do
        subject { TimingFinders::Factory.for(GogglesDb::EntryTimeType.new(code: '')) }
        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context "for a 'prec_year' EntryTimeType" do
        subject { TimingFinders::Factory.for(GogglesDb::EntryTimeType.prec_year) }
        it 'is a BestMIRForMeeting' do
          expect(subject).to be_a(TimingFinders::BestMIRForMeeting)
        end
      end
      context "for a 'gogglecup' EntryTimeType" do
        subject { TimingFinders::Factory.for(GogglesDb::EntryTimeType.gogglecup) }
        it 'is a GoggleCupForEvent' do
          expect(subject).to be_a(TimingFinders::GoggleCupForEvent)
        end
      end
      context "for a 'last_race' EntryTimeType" do
        subject { TimingFinders::Factory.for(GogglesDb::EntryTimeType.last_race) }
        it 'is a LastMIRForEvent' do
          expect(subject).to be_a(TimingFinders::LastMIRForEvent)
        end
      end
      context "for a 'personal' EntryTimeType" do
        subject { TimingFinders::Factory.for(GogglesDb::EntryTimeType.personal) }
        it 'is a BestMIRForEvent' do
          expect(subject).to be_a(TimingFinders::BestMIRForEvent)
        end
      end
      context "for a 'manual' EntryTimeType" do
        subject { TimingFinders::Factory.for(GogglesDb::EntryTimeType.manual) }
        it 'is a NoTimeForEvent' do
          expect(subject).to be_a(TimingFinders::NoTimeForEvent)
        end
      end
    end
  end
end
