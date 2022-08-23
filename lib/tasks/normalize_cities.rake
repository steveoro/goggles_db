# frozen_string_literal: true

require 'goggles_db'
require 'cities'
require_relative '../../app/strategies/goggles_db/normalizers/city_name'

namespace :normalize do
  desc <<~DESC
      Normalizes all country & city names comparing them with the values supplied by the coutries & cities gems

    Options: [simulate=1|<0>]
             [limit=N|<0>]

      - simulate: when positive, the task will only output the prospected changes without actually
                  saving or changing the database at all.
                  (Useful to check the result before corrupting any data)

      - limit: when positive, only the first N rows will be processed (default 0: all rows)

  DESC
  task cities: :environment do
    simulate = ENV.include?('simulate') ? ENV['simulate'].to_i.positive? : false
    limit_rows = ENV.include?('limit') ? ENV['limit'].to_i : 0
    puts "\r\n*** Countries + Cities normalization ***"
    puts '--> SIMULATE MODE ON' if simulate
    puts "\r\n--> Normalizing City names & countries (+ codes)..."
    normalize_city_names(simulate, limit_rows)

    # == Note: *IN CASE OF DATA CORRUPTION*
    #
    # - Always test the running task on the test DB first.
    #
    # - In case the DB becomes corrupted due to new, mistyped entries, use the query below to restore
    #   the first 181 cities (as of this writing, all the other additional cities on test were random
    #   fixtures and thus "trashable"):
    #
    # UPDATE goggles_test.cities AS dest, goggles_development.cities AS src
    #   SET dest.name = src.name,
    #       dest.zip = src.zip,
    #       dest.area = src.area,
    #       dest.country = src.country,
    #       dest.country_code = src.country_code,
    #       dest.latitude = src.latitude,
    #       dest.longitude = src.longitude,
    #       dest.plus_code = src.plus_code
    #   WHERE dest.id = src.id
    #   LIMIT 181;

    puts "\r\nDone."
  end
  #-- -------------------------------------------------------------------------
  #++

  # Scans the cities table for non-standard names, then updates them with their
  # expected "standard" name.
  # Outputs a list of problematic names that may have to be re-processed or fixed manually.
  def normalize_city_names(simulate, limit_rows)
    unknown_names = []
    updated_rows  = 0
    domain = limit_rows.positive? ? GogglesDb::City.limit(limit_rows) : GogglesDb::City.all

    domain.find_each do |city_model|
      normalizer = GogglesDb::Normalizers::CityName.new(city_model, verbose: true)
      city_model = normalizer.process

      # Skip iteration while checking for unknowns:
      if normalizer.iso_country.nil?
        unknown_names << "#{city_model.name} (ID: #{city_model.id})"
        next
      end
      if normalizer.iso_city.nil?
        unknown_names << "#{city_model.name} (ID: #{city_model.id})"
      else
        updated_rows += update_city(normalizer, city_model, simulate)
      end
    end

    puts "\r\nTotal row updates: #{updated_rows}"
    $stdout.write("\033[1;33;31mTO BE FIXED:\033[0m\r\n#{unknown_names.join("\r\n")}\r\n") unless unknown_names.empty?
  end

  # Updates the city_model with an 'update', but only if the update is actually needed.
  # Returns 1 if the update was successful; 0 otherwise.
  #
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def update_city(_normalizer, city_model, simulate)
    # Don't count unless there are changes:
    return 0 unless city_model.has_changes_to_save?

    result = if simulate
               # Manual check for constraint violation:
               already_existing = GogglesDb::City.where('(name = ?) AND (id != ?)', city_model.name, city_model.id)
               if city_model.valid? && already_existing.empty?
                 1
               elsif city_model.valid? && already_existing.present?
                 -1
               else # model not valid
                 0
               end
             else
               city_model.transaction do
                 city_model.save!
                 1
               rescue ActiveRecord::RecordNotUnique
                 -1
               rescue ActiveModel::ValidationError
                 0
               end
             end

    case result
    when 1
      $stdout.write("        updated '#{city_model.name}' (#{city_model.country_code}), area: '#{city_model.area}'" \
                    " lat: '#{city_model.latitude}' long: '#{city_model.longitude}'\r\n")
      return 1
    when -1
      $stdout.write("        \033[1;33;31m× DUPLICATE City ID #{city_model.id} ×\033[0m '#{city_model.name}'\r\n")
    else # 0
      $stdout.write("        \033[1;33;31m× VALIDATION FAILED City ID #{city_model.id} ×\033[0m '#{city_model.name}'\r\n")
    end

    0 # Always return 0 in case of errors (we count the updates only)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  #-- -------------------------------------------------------------------------
  #++
end
