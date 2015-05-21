ActionDispatch::Routing::Mapper.send :include, JsonApiRoutes

require 'sidekiq/web'

Rails.application.routes.draw do

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  use_doorkeeper do
    controllers authorizations: 'authorizations',
                tokens: 'tokens',
                applications: 'applications'
  end

  devise_for :users,
    controllers: { omniauth_callbacks: 'omniauth_callbacks', passwords: 'passwords' },
    skip: [ :sessions, :registrations ]

  as :user do
    get "/users/sign_in" => "sessions#new", as: :new_user_session
    post "/users/sign_in" => "sessions#create", as: :user_session
    delete "/users/sign_out" => "sessions#destroy", as: :destroy_user_session

    get "/users/sign_up" => "registrations#new", as: :new_user_registration
    post "/users" => "registrations#create", as: :user_registration
    put "/users" => "registrations#update"
  end

  namespace :api, constraints: { format: 'json' } do
    post "/events" => "events#create"
  end

  namespace :api do
    api_version(module: "V1", header: {name: "Accept", value: "application/vnd.api+json; version=1"}) do
      get "/me", to: 'users#me', format: false
      json_api_resources :aggregations

      json_api_resources :collection_roles

      json_api_resources :collection_preferences

      json_api_resources :workflow_contents, versioned: true

      json_api_resources :project_contents, versioned: true

      json_api_resources :set_member_subjects, links: [:retired_workflows]

      json_api_resources :project_roles

      json_api_resources :project_preferences

      json_api_resources :classifications

      json_api_resources :memberships

      json_api_resources :subjects, versioned: true

      json_api_resources :users, except: [:new, :edit, :create], links: [:user_groups] do
        get "/recents", to: "users#recents", format: false
        media_resources :avatar
      end

      json_api_resources :groups, links: [:users] do
        get "/recents", to: "groups#recents", format: false
      end

      json_api_resources :projects, links: [:subject_sets, :workflows] do
        media_resources :avatar, :background, :attached_images, classifications_exports: { except: [:update, :create] }
        post "/classifications_exports", to: "projects#create_export", format: false
      end

      json_api_resources :workflows, links: [:subject_sets], versioned: true

      json_api_resources :subject_sets, links: [:subjects]

      json_api_resources :collections, links: [:subjects]

      json_api_resources :subject_queues, links: [:set_member_subjects]
    end
  end

  root to: "home#index"
  match "*path", to: "application#unknown_route", via: :all
end
