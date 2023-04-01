# frozen_string_literal: true

module GogglesDb
  # = IssueDecorator
  #
  class IssueDecorator < Draper::Decorator
    delegate_all

    # Returns an icon or a short label for the #status of this row.
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def state_flag
      case status
      when 0 # new
        h.tag.span h.tag.i(class: 'fa fa-envelope-open-o text-secondary')
      when 1 # in review
        h.tag.span h.tag.i(class: 'fa fa-eye text-info')
      when 2 # accepted/in process
        h.tag.span h.tag.i(class: 'fa fa-cog fa-spin')
      when 3 # accepted/paused
        h.tag.span h.tag.i(class: 'fa fa-hourglass-half text-secondary')
      when 4 # sorted out
        h.tag.i(class: 'fa fa-check text-success')
      when 5 # rejected/duplicate
        h.tag.span(class: 'text-danger') do
          h.tag.i(class: 'fa fa-times') << h.tag.i(class: 'fa fa-question') << ' dup'
        end
      when 6 # rejected/incomplete
        h.tag.span(class: 'text-danger') do
          h.tag.i(class: 'fa fa-times') << h.tag.i(class: 'fa fa-question') << ' miss'
        end
      else # UNSUPPORTED
        h.tag.span(class: 'text-danger') { h.tag.i(class: 'fa fa-question fa-spin') }
      end
    end

    # Returns an icon or a short label for the #code of this row.
    def code_flag
      case code
      when '0'    # upgrade to team manager
        h.tag.span h.tag.i(class: 'fa fa-level-up')
      when '1a'   # new meeting url
        h.tag.span h.tag.i(class: 'fa fa-trophy')
      when '1b'   # missing result
        h.tag.span h.tag.i(class: 'fa fa-plus')
      when '1b1'  # result mistake
        h.tag.span h.tag.i(class: 'fa fa-pencil-square-o')
      when '2b1'  # wrong team/swimmer/meeting
        h.tag.span do
          h.tag.i(class: 'fa fa-trophy') << '?' << h.tag.i(class: 'fa fa-user-o')
        end
      when '3b'   # change swimmer association
        h.tag.span { h.tag.i(class: 'fa fa-address-book-o') }
      when '3c'   # edit associated swimmer details
        h.tag.span do
          h.tag.i(class: 'fa fa-pencil-square-o') << h.tag.i(class: 'fa fa-user-o')
        end
      when '4'    # generic bug
        h.tag.span h.tag.i(class: 'fa fa-bug')
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    # Returns an icon or a short label for the #priority of this row.
    def priority_flag
      case priority
      when 0
        h.tag.i(class: 'fa fa-minus')
      when 1
        h.tag.i(class: 'fa fa-angle-up')
      when 2
        h.tag.i(class: 'fa fa-angle-double-up')
      when 3
        h.tag.i(class: 'fa fa-exclamation-circle text-warning')
      end
    end

    # Returns the a localized text label describing this row, depending on #code
    def text_label
      object.long_label
    end

    alias display_label text_label # (new, old)

    # Returns the a shorter version of #text_label
    def short_label
      object.label
    end
  end
end
