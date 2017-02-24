Rails.application.routes.draw do
  resources :sheets do
    resources :api_keys, only: [:create]
  end

  resources :onboarding do
    member do
      get ":worksheet_id", to:  "onboarding#worksheet", as: :worksheet
    end
  end

  root to: 'sessions#new'
  resources :sessions, only: [:new, :create, :destroy]

  get "/auth/:provider/callback" => 'sessions#create'
  get "logout" => 'sessions#destroy'
end
