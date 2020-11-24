# frozen_string_literal: true

require 'rails_helper'
require 'benchmark'

module GogglesDb
  RSpec.describe EventsByPoolType, type: :performance do
    describe 'self.all_eventable (in its current memoized version),' do
      context 'when compared against the old query version,' do
        it 'is faster' do |example|
          timing1 = Benchmark.measure do
            EventsByPoolType.joins(:pool_type, :stroke_type)
                            .where('pool_types.is_suitable_for_meetings': true)
                            .where('stroke_types.is_eventable': true)
          end
          timing2 = Benchmark.measure { EventsByPoolType.all_eventable }
          expect(timing2.total).to be < timing1.total

          example.reporter.message("\r\n\t- Benchmark for self.eventable:")
          example.reporter.message('                   user     system      total        real')
          example.reporter.message("  query (v6): #{timing1}")
          example.reporter.message("  memo  (v7): #{timing2}")
        end
      end
    end
  end
end
