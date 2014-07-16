Rails.application.routes.draw do

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' },
    skip: [ :registrations, :sessions, :passwords ]

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.api+json; version=1"}) do

      devise_scope :user do
        post   'registrations',   to: 'registrations#create',   as: 'sign_up'
        post   'passwords', to: 'passwords#create', as: 'reset_password'
        match  'passwords', to: 'passwords#update', as: 'reset_password_confirm', via: [:put, :patch]
      end

      get "/me", to: 'users#me', format: false

      resources :users, except: [:new, :edit, :create], format: false

      [:memberships, :groups, :collections, :subjects, :projects,
       :classifications, :workflows, :subject_sets].each do |resource|
          resources resource, except: [:new, :edit], format: false
      end
    end
  end

  root to: "home#index"
  match "*path", to: "application#unknown_route", via: :all
end
