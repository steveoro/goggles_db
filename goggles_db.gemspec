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
  spec.license     = 'LGPL-3.0-or-later'

  spec.required_ruby_version = '>= 3.1.4'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://master-goggles.org' # (Not valid yet)
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  # Base Rails dependancy:
  # [20210128] ActiveRecord 6.1 introduces too many changes for the current implementation
  spec.add_dependency 'rails', '>= 6.0.6.1', '< 6.1.0'
  spec.add_dependency 'rails-i18n', '~> 6.0'

  spec.add_dependency 'acts-as-taggable-on'
  spec.add_dependency 'acts_as_votable'
  # Countries & cities lookup:
  spec.add_dependency 'cities'    # https://github.com/joecorcoran/cities
  spec.add_dependency 'countries' # https://github.com/hexorx/countries
  spec.add_dependency 'country_select'
  spec.add_dependency 'devise'
  spec.add_dependency 'devise-i18n'
  spec.add_dependency 'draper'
  spec.add_dependency 'fuzzy-string-match'
  spec.add_dependency 'haml'
  spec.add_dependency 'haml-rails'
  spec.add_dependency 'jwt'
  spec.add_dependency 'ledermann-rails-settings' # https://github.com/ledermann/rails-settings
  spec.add_dependency 'loofah', '>= 2.2'
  spec.add_dependency 'mini_magick'
  spec.add_dependency 'nokogiri', '>= 1.14.2'
  spec.add_dependency 'omniauth-facebook'
  # Subseeded by google_sign_in used by goggles_main (no Devise/Omniauth dependencies)
  # spec.add_dependency 'omniauth-google-oauth2'
  spec.add_dependency 'omniauth-rails_csrf_protection'
  # Twitter disabled for the time being (supports only OAuth 1a)
  # spec.add_dependency 'omniauth-twitter'
  spec.add_dependency 'plus_codes'      # https://github.com/google/open-location-code/tree/master/ruby
  spec.add_dependency 'ruby2_keywords'  # needed to correct 'delegate' for some peculiar cases until Ruby 3.x is adopted (see: https://eregon.me/blog/2021/02/13/correct-delegation-in-ruby-2-27-3.html)
  spec.add_dependency 'sass-rails'
  spec.add_dependency 'scenic'
  spec.add_dependency 'simple_command'
  spec.add_dependency 'tzinfo'

  spec.add_dependency 'factory_bot_rails'
  spec.add_dependency 'ffaker'
  # NOTE: data factories are published here to allow
  # fixture creation even on staging/production environments

  spec.metadata['rubygems_mfa_required'] = 'true'
end
