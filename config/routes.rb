Rails.application.routes.draw do
  devise_for :users
  namespace :api do
    use_doorkeeper
  end

  root to: "home#index"

end

