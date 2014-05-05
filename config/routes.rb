Rails.application.routes.draw do
  devise_for :users

  use_doorkeeper

  namespace :api do
  end

  root to: "home#index"

end

