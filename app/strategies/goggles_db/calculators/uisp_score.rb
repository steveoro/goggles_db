# frozen_string_literal: true

module GogglesDb
  # Wraps all calculator strategies that can be plugged into <tt>CmdComputeResultScore</tt> by the
  # dedicated factory.
  #
  # The factory will choose & build which strategy has to be used by the command object
  # depending on the specified parameters.
  #
  module Calculators
    #
    # = UISPScore strategy object
    #
    #   - version:  7-0.3.36
    #   - author:   Steve A.
    #   - build:    20211028
    #
    # Allows to compute a UISP championship/season scoring (or timing from a score)
    # given the constructor parameters.
    #
    class UISPScore < BaseStrategy
      # (no customizations so far)
      # TODO: add UISP-specific rules here
    end
  end
end
