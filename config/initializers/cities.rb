# frozen_string_literal: true

require 'cities'

Cities.data_path = GogglesDb::Engine.root.join('db', 'data', 'cities').to_s
# Cities.cache_data = true # (default: true; set this to false in case the memory footprint is too big)
