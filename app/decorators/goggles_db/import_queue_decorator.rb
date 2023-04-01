# frozen_string_literal: true

module GogglesDb
  # = ImportQueueDecorator
  #
  class ImportQueueDecorator < Draper::Decorator
    delegate_all

    # Add explicit delegation for methods needed by Kaminari (if the object is an AR::Relation):
    delegate :current_page, :total_pages, :limit_value, :total_count, :offset_value, :last_page?

    # Returns the a text label for the processing state of this row.
    def state_flag
      return '🟢' if done? # (about to be deleted)
      return '' if process_runs.zero? # (not-yet processed => no status)
      return "▶ #{process_runs}" if process_runs.positive? && process_runs.to_i < 90 # (processing)
      return "🆘 #{process_runs}" if process_runs.positive? # (basically halted)
    end

    # Returns the a bespoke text label describing this row, depending on the
    # group UID.
    def text_label
      return '📃' if batch_sql

      case uid
      when 'chrono'
        chrono_result_label
      when /chrono-\d+/
        chrono_delta_label
      when 'res'
        h.tag.small do
          "📌 #{req_event_type&.label}: #{req_timing}, #{req_swimmer_name} by #{user.name} #{state_flag}"
        end
      else
        h.tag.small do
          "#{target_entity} by #{user.name} #{state_flag}"
        end
      end
    end

    alias display_label text_label # (new, old)
    alias short_label text_label # (new, old)
    #-- ------------------------------------------------------------------------
    #++

    # Assuming the request type is 'chrono' (master row of a Chrono-timing req),
    # this returns a descriptive label for the final recorded timing in this IQ group.
    # Returns an empty string otherwise.
    #
    def chrono_result_label
      return '' unless uid == 'chrono'

      if req_final_timing.positive?
        h.tag.small do
          "⏱ #{req_event_type&.label}: #{req_final_timing}, #{req_swimmer_name} (#{req_swimmer_year_of_birth}) #{state_flag}"
        end
      else
        # Fallback to the default request timing found if the hierarchy/request has been wrongly formed:
        h.tag.small do
          "⏱ #{req_event_type&.label}: #{req_timing} (??), #{req_swimmer_name} (#{req_swimmer_year_of_birth}) #{state_flag}"
        end
      end
    end

    # Assuming the request type is 'chrono-N' (any linked/lap row of a Chrono-timing req),
    # this returns a descriptive label for the current delta lap timing.
    # Returns an empty string otherwise.
    #
    def chrono_delta_label
      return '' unless /chrono-\d+/.match?(uid)

      if req_delta_timing.positive?
        h.tag.small do
          "#{req_timing}, #{req_length_in_meters} m (Δt: #{req_delta_timing}) #{state_flag}"
        end
      else
        h.tag.small do
          "#{req_timing}, #{req_length_in_meters} m #{state_flag}"
        end
      end
    end
  end
end
