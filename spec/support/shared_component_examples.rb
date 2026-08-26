# frozen_string_literal: true

# REQUIRES/ASSUMES:
# - ranking_num.......: storing the subject's ranking position to be rendered
# - rendered_result...: storing the rendered text to be checked
shared_examples_for 'RankingPosComponent rendering a ranking position' do |ranking_num|
  it 'renders a UNICODE medal for rank 0..3 or just the ranking number for any other value' do
    case ranking_num
    when 0..3
      expect(rendered_result).to include(%w[➖ 🥇 🥈 🥉][ranking_num])
    else
      expected = ranking_num.nil? ? '➖' : ranking_num.to_s
      expect(rendered_result).to include(expected)
    end
  end
end
