# frozen_string_literal: true

module GogglesDb
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  end
end
