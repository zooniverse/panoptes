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

  get "unsubscribe", to: "emails#unsubscribe_via_token"
  post "unsubscribe", to: "emails#unsubscribe_via_email"

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

      json_api_resources :classifications do
        collection do
          get :gold_standard
          get :incomplete
          get :project
        end
      end

      json_api_resources :memberships

      json_api_resources :subjects, versioned: true

      json_api_resources :users, except: [:new, :edit, :create], links: [:user_groups] do
        get "/recents", to: "users#recents", format: false
        media_resources :avatar, :profile_header
      end

      json_api_resources :user_groups, links: [:users] do
        get "/recents", to: "user_groups#recents", format: false
      end

      json_api_resources :projects, links: [:subject_sets, :workflows], versioned: true do
        media_resources :avatar, :background, :attached_images,
          classifications_export: { except: [:create] },
          subjects_export: { except: [:create] },
          aggregations_export: { except: [:create] },
          workflows_export: { except: [:create] },
          workflow_contents_export: { except: [:create] }

        post "/classifications_export", to: "projects#create_classifications_export", format: false
        post "/subjects_export", to: "projects#create_subjects_export", format: false
        post "/aggregations_export", to: "projects#create_aggregations_export", format: false
        post "/workflows_export", to: "projects#create_workflows_export", format: false
        post "/workflow_contents_export", to: "projects#create_workflow_contents_export", format: false

        json_api_resources :pages, controller: "project_pages"
      end

      json_api_resources :workflows, links: [:subject_sets, :retired_subjects], versioned: true do
        media_resources :attached_images

        post "/retired_subjects", to: "workflows#retire_subjects"
      end

      json_api_resources :subject_sets, links: [:subjects]

      json_api_resources :collections, links: [:subjects]

      json_api_resources :subject_queues, links: [:subjects]

      json_api_resources :tags, only: [:index, :show]

      json_api_resources :tutorials do
        media_resources :attached_images
      end

      json_api_resources :field_guides do
        media_resources :attached_images
      end
    end
  end

  get "health_check", to: "home#index"
  root to: "home#index"
  match "*path", to: "application#unknown_route", via: :all
end
