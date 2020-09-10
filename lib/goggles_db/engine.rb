# frozen_string_literal: true

require 'devise'
require 'jwt'
require 'draper'
require 'haml'
require 'acts-as-taggable-on'
require 'acts_as_votable'
require 'factory_bot_rails'

module GogglesDb
  class Engine < ::Rails::Engine
    isolate_namespace GogglesDb

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.factory_bot dir: GogglesDb::Engine.root.join('spec', 'factories').to_s
      g.fixture_replacement :factory_bot
      g.assets false
      g.helper false
    end
  end
end
