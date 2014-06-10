Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper do
    controllers applications: 'oauth/applications'
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
end

