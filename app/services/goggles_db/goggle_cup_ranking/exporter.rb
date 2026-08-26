# frozen_string_literal: true

require 'csv'
require 'axlsx'
require 'prawn'
require 'prawn/table'
Prawn::Fonts::AFM.hide_m17n_warning = true

# rubocop:disable-next Metrics/ClassLength, Metrics/AbcSize, Metrics/ParameterLists
module GogglesDb
  module GoggleCupRanking
    # Generates ranking and base-timings exports (CSV, XLSX, PDF) for a Goggle Cup.
    # It is framework-agnostic: callers (controllers) are responsible for sending
    # the generated data to the client with `send_data`.
    class Exporter
      def initialize(ranking_data:, cup: nil, team: nil, no_duplicated_events: false,
                     description: nil, season_year: nil)
        @cup = cup
        @team = team || cup&.team
        @ranking_data = ranking_data || []
        @no_duplicated_events = no_duplicated_events
        @description = description.presence || cup&.description
        @season_year = season_year || cup&.season_year || Date.current.year
      end

      # Returns a hash with :data, :filename and :mime_type, or nil when there
      # is no data for the requested export type.
      def export(format_name:, export_type: :ranking)
        return nil unless data_present_for?(export_type)

        {
          data: send(:"to_#{format_name}", export_type: export_type),
          filename: filename(format: format_name, export_type: export_type),
          mime_type: mime_type_for(format_name)
        }
      end

      def to_csv(export_type: :ranking)
        CSV.generate(headers: true) do |csv|
          if export_type.to_s == 'base_timings'
            csv << base_timings_csv_headers
            base_timings_export_data.each do |data|
              data[:base_rows].each { |row| csv << base_timings_row_for(data, row) }
            end
          else
            csv << ranking_csv_headers
            @ranking_data.each_with_index do |data, index|
              csv << ranking_row_for(data, index)
            end
          end
        end
      end

      def to_xlsx(export_type: :ranking)
        if export_type.to_s == 'base_timings'
          generate_base_timings_xlsx
        else
          generate_ranking_xlsx
        end
      end

      def to_pdf(export_type: :ranking)
        if export_type.to_s == 'base_timings'
          generate_base_timings_pdf
        else
          generate_ranking_pdf
        end
      end

      def filename(format:, export_type: :ranking)
        suffix = export_type.to_s == 'base_timings' ? '-base-timings' : ''
        team_name = @team&.name&.parameterize || 'team'
        desc = @description.to_s.parameterize
        desc = team_name if desc.blank?
        "goggle-cup-#{@season_year}-#{team_name}-#{desc}#{suffix}.#{format}"
      end

      MIME_TYPES = {
        csv: 'text/csv',
        xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        pdf: 'application/pdf'
      }.freeze

      private

      def data_present_for?(export_type)
        if export_type.to_s == 'base_timings'
          base_timings_export_data.any?
        else
          @ranking_data.present?
        end
      end

      def base_timings_export_data
        @base_timings_export_data ||= BaseTimingsData.new(@ranking_data).call
      end

      def mime_type_for(format_name)
        MIME_TYPES[format_name.to_sym]
      end

      def team_name_for_sheet
        @team&.name&.truncate(18) || 'Team'
      end

      # --- Ranking XLSX/PDF --------------------------------------------------

      def generate_ranking_xlsx
        package = Axlsx::Package.new
        workbook = package.workbook
        header_style = workbook.styles.add_style(b: true, sz: 12, bg_color: 'DDDDDD', alignment: { horizontal: :center })
        data_style = workbook.styles.add_style(sz: 11)
        right_style = workbook.styles.add_style(sz: 11, alignment: { horizontal: :right })

        workbook.add_worksheet(name: "GoggleCup-#{team_name_for_sheet}") do |sheet|
          title = I18n.t('goggles_cup.ranking_for_team', team: @team&.name)
          sheet.add_row [title], style: header_style
          sheet.merge_cells 'A1:E1'
          sheet.add_row
          sheet.add_row ranking_csv_headers, style: header_style
          @ranking_data.each_with_index do |data, index|
            sheet.add_row ranking_row_for(data, index),
                          style: [right_style, data_style, right_style, right_style, right_style]
          end
          sheet.column_widths 6, 40, 10, 12, 8
        end

        package.to_stream.read
      end

      def generate_ranking_pdf
        Prawn::Document.new(page_layout: :portrait, margin: 25) do |pdf|
          pdf.font_size 10
          pdf.text(I18n.t('goggles_cup.ranking_for_team', team: @team&.name), size: 16, style: :bold, align: :center)
          pdf.move_down 4
          if @cup
            pdf.text("#{@cup.season_year} — #{@cup.description}", size: 12, style: :bold, align: :center)
            pdf.move_down 2
          end
          # Draw the additional rule only if toggled on:
          if @no_duplicated_events
            pdf.text(I18n.t('goggles_cup.no_duplicated_events'), size: 8, align: :center)
            pdf.move_up 10
            checkbox_x = (pdf.bounds.width / 2) + (pdf.width_of(I18n.t('goggles_cup.no_duplicated_events'), size: 8) / 2) + 4
            checkbox_y = pdf.cursor
            pdf.stroke_rectangle([checkbox_x, checkbox_y], 8, 8)
            pdf.fill_color '000000'
            pdf.text_box('X', at: [checkbox_x + 1.5, checkbox_y - 1], size: 7)
          end
          pdf.move_down 12
          pdf.text("#{I18n.t('goggles_cup.computation_details')}, #{I18n.t('goggles_cup.formula')}", size: 8, align: :center)
          pdf.move_down 8

          @ranking_data.each_with_index do |data, index|
            pdf.start_new_page if pdf.cursor < 150

            pdf.text("##{index + 1}  #{data[:swimmer_name]}  (#{data[:swimmer_year_of_birth]})",
                     size: 12, style: :bold)
            pdf.move_up 10
            pdf.text("#{I18n.t('goggles_cup.overall_score', score: format('%.2f', data[:overall_score]))}  —  ID #{data[:swimmer_id]}",
                     size: 9, color: '000088', style: :bold, align: :right)
            pdf.move_down 4

            table_data = pdf_ranking_table_data(data[:top_rows])
            pdf.table(table_data, header: true, row_colors: %w[F0F0F0 FFFFFF],
                                  width: pdf.bounds.width, cell_style: { size: 7, padding: [2, 3] }) do |table|
              table.row(0).font_style = :bold
              table.column(2).align = :right
              table.column(4).align = :right
              table.column(5).align = :right
            end
            pdf.move_down 20
          end
        end.render
      end

      def ranking_csv_headers
        [
          I18n.t('goggles_cup.export.csv.rank'),
          I18n.t('goggles_cup.swimmer_name'),
          I18n.t('goggles_cup.year_of_birth'),
          I18n.t('goggles_cup.export.csv.overall_score'),
          I18n.t('goggles_cup.export.csv.swimmer_id')
        ]
      end

      def ranking_row_for(data, index)
        [
          index + 1,
          data[:swimmer_name],
          data[:swimmer_year_of_birth],
          format('%.2f', data[:overall_score]),
          data[:swimmer_id]
        ]
      end

      def pdf_ranking_table_data(top_rows)
        header = [
          I18n.t('goggles_cup.event_type'),
          I18n.t('goggles_cup.meeting_name'),
          I18n.t('goggles_cup.total_hundredths'),
          I18n.t('goggles_cup.old_meeting_name'),
          I18n.t('goggles_cup.old_total_hundredths'),
          I18n.t('goggles_cup.row_score')
        ]
        rows = top_rows.map do |top_row|
          row = top_row[:row]
          meeting_info = "#{row.meeting_date}, #{row.meeting_name}\nMeeting ID #{row.meeting_id}, MIR #{row.meeting_individual_result_id}"
          current_timing = "#{row.total_hundredths}\n#{Timing.new.from_hundredths(row.total_hundredths.to_i)}"

          if row.old_meeting_date.present?
            old_meeting_info = "#{row.old_meeting_date}, #{row.old_meeting_name}\nMeeting ID #{row.old_meeting_id}, MIR #{row.old_meeting_individual_result_id}"
            old_timing = "#{row.old_total_hundredths}\n#{Timing.new.from_hundredths(row.old_total_hundredths.to_i)}"
          else
            old_meeting_info = '-'
            old_timing = '-'
          end

          [
            "#{row.event_type_code} #{row.pool_type_code}m",
            meeting_info,
            current_timing,
            old_meeting_info,
            old_timing,
            format('%.2f', top_row[:row_score])
          ]
        end
        [header] + rows
      end

      # --- Base timings XLSX/PDF ---------------------------------------------

      def generate_base_timings_xlsx
        package = Axlsx::Package.new
        workbook = package.workbook
        header_style = workbook.styles.add_style(b: true, sz: 12, bg_color: 'DDDDDD', alignment: { horizontal: :center })
        data_style = workbook.styles.add_style(sz: 11)
        right_style = workbook.styles.add_style(sz: 11, alignment: { horizontal: :right })

        workbook.add_worksheet(name: "BaseTimings-#{team_name_for_sheet}") do |sheet|
          title = I18n.t('goggles_cup.base_timings.title')
          sheet.add_row [title, '', '', '', '', '', ''], style: header_style
          sheet.merge_cells 'A1:G1'
          sheet.add_row [I18n.t('goggles_cup.ranking_for_team', team: @team&.name), '', '', '', '', '', ''], style: header_style
          sheet.merge_cells 'A2:G2'
          sheet.add_row
          sheet.add_row base_timings_csv_headers, style: header_style
          base_timings_export_data.each do |data|
            data[:base_rows].each do |row|
              sheet.add_row base_timings_row_for(data, row),
                            style: [data_style, right_style, data_style, data_style, data_style, data_style, right_style]
            end
          end
          sheet.column_widths 30, 10, 12, 15, 40, 8, 15
        end

        package.to_stream.read
      end

      def generate_base_timings_pdf
        Prawn::Document.new(page_layout: :portrait, margin: 25) do |pdf|
          pdf.font_size 10
          pdf.text(I18n.t('goggles_cup.base_timings.title'), size: 16, style: :bold, align: :center)
          pdf.move_down 4
          pdf.text(I18n.t('goggles_cup.ranking_for_team', team: @team&.name), size: 12, align: :center)
          if @cup
            pdf.move_down 2
            pdf.text("#{@cup.season_year} — #{@cup.description}", size: 11, style: :bold, align: :center)
          end
          pdf.move_down 12

          base_timings_export_data.each do |data|
            pdf.start_new_page if pdf.cursor < 140

            pdf.text("#{data[:swimmer_name]}  (#{data[:swimmer_year_of_birth]})  —  ID #{data[:swimmer_id]}",
                     size: 11, style: :bold)
            pdf.move_down 4

            table_data = pdf_base_timings_table_data(data[:base_rows])
            pdf.table(table_data, header: true, row_colors: %w[F0F0F0 FFFFFF],
                                  width: pdf.bounds.width, cell_style: { size: 8, padding: [2, 3] }) do |table|
              table.row(0).font_style = :bold
              table.column(2).align = :right
              table.column(5).align = :right
            end
            pdf.move_down 16
          end
        end.render
      end

      def base_timings_csv_headers
        [
          I18n.t('goggles_cup.swimmer_name'),
          I18n.t('goggles_cup.year_of_birth'),
          I18n.t('goggles_cup.base_timings.event_type'),
          I18n.t('goggles_cup.base_timings.pool_type'),
          I18n.t('goggles_cup.base_timings.season'),
          I18n.t('goggles_cup.base_timings.meeting'),
          I18n.t('goggles_cup.base_timings.timing')
        ]
      end

      def base_timings_row_for(data, row)
        meeting_info = "#{row.meeting_date}, #{row.meeting_name}\nMeeting ID #{row.meeting_id}, MIR #{row.meeting_individual_result_id}"
        timing = "#{row.total_hundredths}\n#{Timing.new.from_hundredths(row.total_hundredths.to_i)}"
        [
          data[:swimmer_name],
          data[:swimmer_year_of_birth],
          "#{row.event_type_code} #{row.pool_type_code}m",
          row.pool_type_code,
          row.season_header_year,
          meeting_info,
          timing
        ]
      end

      def pdf_base_timings_table_data(base_rows)
        header = [
          I18n.t('goggles_cup.base_timings.event_type'),
          I18n.t('goggles_cup.base_timings.pool_type'),
          I18n.t('goggles_cup.base_timings.season'),
          I18n.t('goggles_cup.base_timings.meeting'),
          I18n.t('goggles_cup.base_timings.timing')
        ]
        rows = base_rows.map do |row|
          meeting_info = "#{row.meeting_date}, #{row.meeting_name}\nMeeting ID #{row.meeting_id}, MIR #{row.meeting_individual_result_id}"
          timing = "#{row.total_hundredths}\n#{Timing.new.from_hundredths(row.total_hundredths.to_i)}"
          [
            "#{row.event_type_code} #{row.pool_type_code}m",
            row.pool_type_code,
            row.season_header_year,
            meeting_info,
            timing
          ]
        end
        [header] + rows
      end
    end
  end
end
