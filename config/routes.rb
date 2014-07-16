Rails.application.routes.draw do

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks', passwords: 'passwords' }, skip: [ :sessions, :registrations ]

  as :user do
    get "/users/sign_in" => "sessions#new", as: :new_user_session
    post "/users/sign_in" => "sessions#create", as: :user_session
    delete "/users/sign_out" => "sessions#destroy", as: :destroy_user_session

    get "/users/sign_up" => "registrations#new", as: :new_user_registration
    post "/users" => "registrations#create", as: :user_registration
  end

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.api+json; version=1"}) do
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
