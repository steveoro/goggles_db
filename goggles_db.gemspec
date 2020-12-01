# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'goggles_db/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'goggles_db'
  spec.version     = GogglesDb::VERSION
  spec.authors     = ['steveoro']
  spec.email       = ['steve.alloro@gmail.com']
  spec.homepage    = 'https://www.master-goggles.org'
  spec.summary     = 'Goggles DB engine'
  spec.description = 'contains just the models and the DB structure required to run the main Goggles app'
  spec.license     = 'GPL-3.0-or-later'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://master-goggles.org' # (Not valid yet)
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  # Base Rails dependancy:
  spec.add_dependency 'rails', '~> 6', '>= 6.0.3.3'

  spec.add_dependency 'acts-as-taggable-on'
  spec.add_dependency 'acts_as_votable'
  spec.add_dependency 'carrierwave' # requires mini_magick for image manipulation

  # Countries & cities lookup:
  spec.add_dependency 'cities'    # https://github.com/joecorcoran/cities
  spec.add_dependency 'countries' # https://github.com/hexorx/countries
  spec.add_dependency 'country_select'

  spec.add_dependency 'devise'
  spec.add_dependency 'devise-i18n'
  spec.add_dependency 'draper'
  spec.add_dependency 'haml'
  spec.add_dependency 'jwt'
  spec.add_dependency 'mini_magick'
  spec.add_dependency 'simple_command'
  spec.add_dependency 'tzinfo', '~> 1.2', '>= 1.2.2'

  # Currently publishing data factories even on production to allow
  # fixture creation even on staging/production environment for testing purposes:
  spec.add_dependency 'factory_bot_rails'
  spec.add_dependency 'ffaker'
  spec.add_dependency 'fuzzy-string-match'

  spec.add_development_dependency 'mysql2'
end
