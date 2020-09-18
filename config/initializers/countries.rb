# frozen_string_literal: true

require 'countries'

# Load only supported locales, when available, to minimize memory footprint in
# production:
ISO3166.configure do |config|
  config.locales = %i[en it de fr es]
end
