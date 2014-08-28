Rails.application.routes.draw do

  use_doorkeeper do
    controllers authorizations: 'authorizations',
      tokens: 'tokens'
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

      resource_classes = [ :memberships, :groups, :collections, :subjects,
                           :projects, :classifications, :workflows,
                           :subject_sets ]
      except = [:new, :edit]

      resource_classes.each do |resource|
        resources resource, except: except, format: false do
          post "/links/:link_relation", to: "#{ resource }#update_links", format: false
          delete "/links/:link_relation(/:link_ids)", to: "#{ resource }#destroy_links", format: false
        end
      end
    end
  end

  root to: "home#index"
  match "*path", to: "application#unknown_route", via: :all
end
