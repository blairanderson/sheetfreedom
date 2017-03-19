Rails.application.routes.draw do
  resources :sheets do
    resources :api_keys, only: [:create]
    resources :visuals, only: [:index] do
      collection do
        get :data
      end
    end
  end

  resources :onboarding, only: [:index, :show, :create] do
    member do
      get ":worksheet_id", to:  "onboarding#worksheet", as: :worksheet
    end
  end

  root to: 'sessions#new'
  resources :sessions, only: [:new, :create, :destroy]

  get "/auth/:provider/callback" => 'sessions#create'
  get "logout" => 'sessions#destroy'
end
