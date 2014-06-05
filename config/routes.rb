Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.api+json; version=1"}) do
      get "/me", to: 'users#show', format: false

      resources :users, param: :name, except: [:new, :edit], format: false do
        resources :collections, only: :index, format: false
        resources :projects, only: :index, format: false
        resources :subjects, only: :index, format: false
        resources :classifications, path: "recents", only: :index, format: false
      end

      resources :groups, param: :name, except: [:new, :edit], format: false do
        resources :collections, only: :index, format: false
        resources :projects, only: :index, format: false
        resources :subjects, only: :index, format: false
        resources :members, only: :index, format: false
        resources :classifications, path: "recents", only: :index, format: false
      end

      resources :collections, only: [:index, :create], format: false
      scope "/collections/:owner_name/", format: false do
        resources :collections, path: '', param: :name, only: [:show, :delete, :update], format: false do
          resources :subjects, only: :index, format: false
        end
      end

      resources :subjects, except: [:new, :edit], format: false

      resources :projects, only: [:index, :create], format: false
      scope "/projects/:owner_name/" do
        resources :projects, path: '', param: :name, only: [:show, :update, :delete], format: false do
          resources :classifications, except: [:new, :edit], format: false
          resources :workflows, except: [:new, :edit], format: false do
            resources :subjects, only: :index, format: false
          end
          resources :subject_sets, except: [:new, :edit], format: false do 
            resources :subjects, only: :index, format: false
          end
        end
      end
    end
  end

  root to: "home#index"
end

