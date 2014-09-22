
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
      except = [:new, :edit]
      
      get "/me", to: 'users#me', format: false
      
      resources :classifications, except: except, format: false
      resources :memberships, except: except, format: false
      resources :subjects, except: except, format: false

      resources :users, except: [:new, :edit, :create], format: false do
        post "/links/:link_relation", to: "users#update_links",
          constraints: { link_relation: /user_groups/ }, format: false
        delete "/links/:link_relation/:link_ids", to: "users#destroy_links",
          constraints: { link_relation: /user_groups/ }, format: false
      end
      
      resources :groups, except: except, format: false do
        post "/links/:link_relation", to: "groups#update_links",
          constraints: { link_relation: /users/ }, format: false
        delete "/links/:link_relation/:link_ids", to: "group#update_links",
          constraints: { link_relation: /users/ }, format: false
      end

      resources :projects, except: except, format: false do
        post "/links/:link_relation", to: "projects#update_links",
          constraints: { link_relation: /(subject_sets|workflows)/ }, format: false
        delete "/links/:link_relation/:link_ids", to: "projects#destroy_links",
          constraints: { link_relation: /(subject_sets|workflows)/ }, format: false
      end
      
      resources :workflows, except: except, format: false do
        post "/links/:link_relation", to: "workflows#update_links",
          constraints: { link_relation: /subject_sets/ }, format: false
        delete "/links/:link_relation(/:link_ids)", to: "workflows#destroy_links",
          constraints: { link_relation: /subject_sets/ }, format: false
      end
      
      resources :subject_sets, except: except, format: false do
        post "/links/:link_relation", to: "subject_sets#update_links",
          constraints: { link_relation: /(workflows|subjects)/ }, format: false
        delete "/links/:link_relation/:link_ids", to: "subject_sets#destroy_links",
          constraints: { link_relation: /(workflows|subjects)/ }, format: false
      end
      
      resources :collections, except: except, format: false do
        post "/links/:link_relation", to: "collections#update_links",
          constraints: { link_relation: /subjects/ }, format: false
        delete "/links/:link_relation/:link_ids", to: "collections#destroy_links",
          constraints: { link_relation: /subjects/ }, format: false
      end
    end
  end

  root to: "home#index"
  match "*path", to: "application#unknown_route", via: :all
end
