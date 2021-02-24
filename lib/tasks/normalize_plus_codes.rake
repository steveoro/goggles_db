# frozen_string_literal: true

require 'goggles_db'
require 'plus_codes/open_location_code'

namespace :normalize do
  desc 'Updates all plus codes from existing coordinates but only if the plus code is empty'
  task plus_codes: :environment do
    puts "\r\n*** Plus codes from coordinates ***"
    puts "\r\n--> Processing cities..."
    update_plus_codes_for(GogglesDb::City)
    puts "\r\n--> Processing swimming pools..."
    update_plus_codes_for(GogglesDb::SwimmingPool)
    puts "\r\nDone."
  end
  #-- -------------------------------------------------------------------------
  #++

  # Scans the specified model class updating the +plus_code+ column whenever it is found
  # empty and both the longitude & latitude are present.
  def update_plus_codes_for(model_class)
    olc = PlusCodes::OpenLocationCode.new
    updated_rows = 0
    # ANSI color codes: 31m = red; 32m = green; 33m = yellow; 34m = blue; 37m = white

    model_class.where(plus_code: [nil, '']).find_each do |model|
      next unless model.latitude.present? && model.longitude.present?

      model.update!(plus_code: olc.encode(model.latitude.to_f, model.longitude.to_f))
      $stdout.write("\033[1;33;32m.\033[0m")
      updated_rows += 1
    end

    puts "\r\nTotal row updates: #{updated_rows}/#{model_class.count}"
  end
  #-- -------------------------------------------------------------------------
  #++
end
