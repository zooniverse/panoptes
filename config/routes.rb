Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper

  namespace :api do
    api_version(:module => "V1", :header => {name: "Accept", :value => "application/vnd.zooniverse.v1+json"}) do
      resource :users, :except => [:new, :edit]
    end
  end

  root to: "home#index"
end

