# frozen_string_literal: true

require 'goggles_db'
require 'cities'

namespace :normalize do
  desc "Normalizes all country codes & names comparing them with the values supplied by the 'coutries' gem"
  task countries: :environment do
    puts "\r\n*** Normalizing Countries for Cities ***"
    unknown_names = []
    updated_countries = 0

    GogglesDb::City.select(:country, :country_code).distinct(:country).each do |city_model|
      normalized_country = ISO3166::Country.find_country_by_name(city_model.country) ||
                           ISO3166::Country.find_country_by_unofficial_names(city_model.country)
      # ANSI color codes: 31m = red; 32m = green; 33m = yellow; 34m = blue; 37m = white
      if normalized_country
        $stdout.write("\033[1;33;32m-\033[0m '#{city_model.country}' →  '#{normalized_country.unofficial_names.first}', ")
      else
        $stdout.write("\033[1;33;33m-\033[0m '#{city_model.country}' \033[1;33;37mNOT found\033[0m, checking country code... ")
        # 3rd and last try by alpha country code:
        normalized_country = ISO3166::Country.send("find_country_by_alpha#{city_model.country_code.length < 3 ? 2 : 3}", city_model.country_code)
      end

      if normalized_country
        $stdout.write("\033[1;33;32mOK\033[0m →  (#{normalized_country.alpha3})\r\n")
        updated_countries += GogglesDb::City.where(country: city_model.country).update_all(
          country_code: normalized_country.alpha3,
          country: normalized_country.unofficial_names.first
        )
      else
        $stdout.write("'#{city_model.country_code}' \033[1;33;31m× UNKNOWN ×\033[0m\r\n")
        unknown_names << city_model.country
      end
    end

    puts "\r\nTotal row updates: #{updated_countries}"
    $stdout.write("\033[1;33;31mTO BE FIXED:\033[0m\r\n'#{unknown_names.join("\r\n")}'\r\n") unless unknown_names.empty?
    puts "\r\nDone."
  end
end
