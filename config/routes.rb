Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.api+json; version=1"}) do
      get "/me", to: 'users#show', format: false

      resources :users, except: [:new, :edit], format: false do 
        resources :collections, only: :index, format: false
        resources :projects, only: :index, format: false
      end

      resources :groups, except: [:new, :edit], format: false do
        resources :collections, only: :index, format: false
        resources :projects, only: :index, format: false
      end

      scope "/collections/:ownername/" do
        resources :collections, path: '', except: [:new, :edit], format: false do
          resources :subjects, only: :index, format: false
        end
      end

      resources :subjects, except: [:new, :edit], format: false

      scope "/projects/:ownername/" do
        resources :projects, path: '', except: [:new, :edit], format: false do
          resources :classifications, except: [:new, :edit], format: false
          resources :workflows, except: [:new, :edit], format: false
          resources :subject_sets, except: [:new, :edit], format: false do 
            resources :subjects, only: :index, format: false
          end
        end
      end
    end
  end

  root to: "home#index"
end

