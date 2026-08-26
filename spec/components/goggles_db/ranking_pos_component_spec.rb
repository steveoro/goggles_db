# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::RankingPosComponent, type: :component do
  [-1, 0, 1, 2, 3, 3 + (rand * 100).to_i].each do |ranking_num|
    context "when rank is #{ranking_num}," do
      let(:rendered_result) { render_inline(described_class.new(rank: ranking_num)).to_html }

      it_behaves_like('RankingPosComponent rendering a ranking position', ranking_num)
    end
  end

  context 'when rank is nil' do
    let(:rendered_result) { render_inline(described_class.new(rank: nil)).to_html }

    it 'renders the no-rank dash' do
      expect(rendered_result).to include('➖')
    end
  end

  it 'renders a tooltip with dsq_notes' do
    result = render_inline(described_class.new(rank: 1, dsq_notes: 'Disqualified')).to_html
    expect(result).to include('Disqualified')
  end

  it 'uses the custom css class' do
    result = render_inline(described_class.new(rank: 2, css: 'my-rank-class')).to_html
    expect(result).to include('my-rank-class')
  end
end
