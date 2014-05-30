Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.zooniverse.v1+json"}) do
      get "/me", to: 'users#show'

      resources :users, except: [:new, :edit] do 
        resources :collections, except: [:new, :edit]
        resources :projects, except: [:new, :edit] do
          resources :classifications, except: [:new, :edit]
          resources :workflows, except: [:new, :edit]
          resources :subject_sets, except: [:new, :edit] do 
            resources :subjects, except: [:new, :edit]
          end
        end
      end

      resources :groups, except: [:new, :edit] do
        resources :collections, except: [:new, :edit]
        resources :projects, except: [:new, :edit] do
          resources :classifications, except: [:new, :edit]
          resources :workflows, except: [:new, :edit]
          resources :subject_sets, except: [:new, :edit] do 
            resources :subjects, except: [:new, :edit]
          end
        end
      end

      scope "/collections/:ownername/" do
        resources :collections, path: '', except: [:new, :edit] do
          resources :subjects, except: [:new, :edit]
        end
      end

      resources :subjects, except: [:new, :edit]

      scope "/projects/:ownername/" do
        resources :projects, path: '', except: [:new, :edit] do
          resources :classifications, except: [:new, :edit]
          resources :workflows, except: [:new, :edit]
          resources :subject_sets, except: [:new, :edit] do 
            resources :subjects, except: [:new, :edit]
          end
        end
      end
    end
  end

  root to: "home#index"
end

