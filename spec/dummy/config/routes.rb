# frozen_string_literal: true

Rails.application.routes.draw do
  mount GogglesDb::Engine => '/goggles_db'
end
