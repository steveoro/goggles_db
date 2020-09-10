# frozen_string_literal: true

GogglesDb::Engine.routes.draw do
  devise_for :users, class_name: 'GogglesDb::User'
end
