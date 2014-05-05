Rails.application.routes.draw do
  get 'home/index'

  get 'home_controller/index'

  devise_for :users
  use_doorkeeper

  namespace :api do
  end

  root to: "home#index"

end

