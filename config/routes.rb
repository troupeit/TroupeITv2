Rails.application.routes.draw do
  devise_for :users, controllers: {
               omniauth_callbacks: "users/omniauth_callbacks",
               registrations: "users/registrations",
               passwords: "passwords"
  }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: "home#index"

  # About Pages
  get "/about/privacy"
  get "/about/tos"
  get "/about/support"

  get "/about/faq"

  devise_scope :user do
    get "/users/auth/:provider" => "users/omniauth_callbacks#passthru"
    get "/users/auth/:provider/upgrade" => "users/omniauth_callbacks#upgrade", as: :user_omniauth_upgrade
    get "/users/auth/:provider/setup", to: "users/omniauth_callbacks#setup"
  end

  get "/users/me", to: "users#me"
  
  resources :users, only: [ :show, :index, :edit, :update, :destroy ]

  resources :users do
    member do
      get :undelete
      get :become
      get :recent_acts
      get :recent_shows
      get :company_memberships
    end
  end
end
