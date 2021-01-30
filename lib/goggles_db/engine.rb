# frozen_string_literal: true

require 'devise'
require 'jwt'
require 'draper'
require 'haml'
require 'acts-as-taggable-on'
require 'acts_as_votable'
require 'factory_bot_rails'

require 'extensions/integer'

# = GogglesDb
#
# DB structure and base Rails models for the Goggles Framework applications.
#
module GogglesDb
  class Engine < ::Rails::Engine
    isolate_namespace GogglesDb

    # Add load paths for this specific Engine:
    # (Prefer eager_load_paths over autoload_paths, since eager_load_paths are
    #  being used in production environment too)
    config.eager_load_paths << GogglesDb::Engine.root.join('lib', 'extensions').to_s
    config.eager_load_paths << GogglesDb::Engine.root.join('lib', 'wrappers').to_s
    # [Steve A.] When in doubt, to check out the actual resulting paths, open the console and type:
    #   $> puts ActiveSupport::Dependencies.eager_load_paths
    # ...Or...
    #   $> puts ActiveSupport::Dependencies.autoload_paths

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.factory_bot dir: GogglesDb::Engine.root.join('spec', 'factories').to_s
      g.fixture_replacement :factory_bot
      g.assets false
      g.helper false
    end
  end
end
