Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.zooniverse.v1+json"}) do
      get "me", to: 'users#show'
      resource :users, :except => [:new, :edit]
    end
  end

  root to: "home#index"
end

