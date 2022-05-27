# frozen_string_literal: true

shared_examples_for 'DbFinders::BaseStrategy with invalid parameters' do
  context 'without a search query parameter,' do
    subject { described_class.new }

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context 'with just the :toggle_debug parameter,' do
    subject { described_class.new(toggle_debug: true) }

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
#-- --------------------------------------------------------------------------
#++

shared_examples_for 'DbFinders::BaseStrategy successful #scan_for_matches' do
  describe '#matches' do
    it 'is not empty' do
      expect(subject.matches).to be_present
    end

    it 'is an array of OpenStruct, each with a candidate and a weight' do
      expect(subject.matches).to all respond_to(:candidate).and respond_to(:weight)
    end
  end
end
#-- --------------------------------------------------------------------------
#++
