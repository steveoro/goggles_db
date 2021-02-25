# frozen_string_literal: true

GogglesDb::Engine.routes.draw do
  devise_for :users, class_name: 'GogglesDb::User'
  # [Steve, 2021025] Add this option to the mounting app:
  # (@see https://github.com/zquestz/omniauth-google-oauth2#devise)
  #
  #      ..., controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
end
