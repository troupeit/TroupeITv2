Rails.application.routes.draw do
  # Defines the root path route ("/")]
  root to: "home#index"

  # Reveal health status on /up that returns 200 if the app boots with no
  # exceptions, otherwise 500. Can be used by load balancers and uptime monitors
  # to verify that the app is live.

  get "up" => "rails/health#show", as: :rails_health_check

  # USERS: Devise routes for user authentication
  devise_for :users, controllers: {
               omniauth_callbacks: "users/omniauth_callbacks",
               registrations: "users/registrations",
               passwords: "passwords"
  }

  devise_scope :user do
    get "/users/auth/:provider" => "users/omniauth_callbacks#passthru"
    get "/users/auth/:provider/upgrade" => "users/omniauth_callbacks#upgrade", as: :user_omniauth_upgrade
    get "/users/auth/:provider/setup", to: "users/omniauth_callbacks#setup"
  end

  get "/users/me", to: "users#me"

  # API Keys (do we need to keep this? Can we remove?)
  post "apikeys/revoke_all"
  post "apikeys/pair"
  get "activate", controller: :apikeys, action: :index

  resources :apikeys, only: [ :create, :destroy, :index, :show ]

  resources :signup_invites
  resources :stats
  resources :deciders

  resources :events do
    collection do
      get :accepting_submissions
    end

    member do
      get :showpage
      get :submissions
      get :tasks
      get :live
    end
  end

  resources :tasks do
    collection do
      post :update_seq
    end
  end

  resources :event_submissions

  resources :roles

  resources :entry_techinfo

  resources :entries

  resources :bhofreviews
  resources :bhof_members

  post "/bhof/verify",
    controller: "bhof",
    action: "verify"

  # shopping cart for badges via stripe
  resources :badge do
    collection do
      get :iforgot
      get :success
      get :success_ship
      get :cancelled
    end
  end

  resources :apps do
    collection do
      get :adminindex
      get :scoreindex
      get :users
      get :finalreport
      get :finalvideos
    end

    member do
      get :dashboard
      get :express_checkout
      get :payment_cancel
      get :payment_paid
      get :review
      get :resultmodal

      post :rsvp
      post :unlock
      post :lock

      post :charge
    end

    resources :entries

    # /apps/:app_id/entry_techinfo(.:format)
    resources :entry_techinfo
    resources :bhofreviews
  end

  resources :leads, only: [ :create ]
  resources :notifications do
    collection do
      get :index
      get :history
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :profiles do
    member do
      get :company
      get :user
    end
  end

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

  # company invoices
  get "invoices/", controller: :invoices, action: :index
  get "invoices/detail"

  resources :companies do
    collection do
      get :manage_access
      get :adminindex
    end

    member do
      get :members
      get :billing
      get :invite_codes

      post :join
      post :leave
      post :regenerate

      post :make_comp
    end
  end

  resources :companies

  get "/company_memberships/search"

  resources :company_memberships

  # bhof routes
  get "/appdashboard", to: "bhof#dashboard"
  get "/bhof/users", to: "bhof#users"

  resources :bhof, only: [ :show, :index ]

  get "/invitation/accept", to: "invitation#accept"
  resources :invitation, only: [ :index, :destroy, :create ]
  resources :invitation do
    member do
      get :accept
    end
  end

  # overriding devise here to deal with users w/o passwords
  post "/settings/otp_activate"
  post "/settings/otp_deactivate"
  post "/settings/update"

  get "/settings/edit_card"
  post "/settings/update_card"

  get "/settings/edit"
  get "/settings/otp_precheck"

  get "/settings/extend_trial"

  # mobile verification
  get "/settings/confirm_mobile"
  post "/settings/verify_mobile"

  get "/passets/new"
  post "/passets/create"

  post "/passets/webhook-xqjrsDasW2Rkhep9r8gju.json",
    controller: "passets",
    action: "webhook"

  post "/acts/new",
    controller: "acts",
    action: "create"

  # override
  get "/acts/self",
    controller: "acts",
    action: "index",
    id: "self"

  resources :acts do
    collection do
      get :adminindex
      get :search
    end

    member do
      post :transfer
    end
  end

  resources :passets do
   collection do
     get :search
     get :adminindex
     get :index
   end

   member do
     get :download
     post :enqueue
   end
  end

  resources :shows do
   member do
      get "live"
      get "perfindex"
      get "items"
      get "show_items"
      get "download"
      get :download_redir
      get "refresh_act_times"
      get "passets"
   end
  end

  resources :show_items
  resources :show_item_notes

  post "/subscription_plan/webhook-APja9YeBiThWKrZQsg3A.json",
    controller: "subscription_plan",
    action: "webhook"

  post "/subscription_plan/charge.json",
    controller: "subscription_plan",
    action: "charge"

  post "/subscription_plan/:company_id/cancel",
    controller: "subscription_plan",
    action: "cancel"

  post "/subscription_plan/:company_id/change",
    controller: "subscription_plan",
    action: "change"

  post "/show_items/update_seq",
    controller: "show_items",
    action: "update_seq"

  post "/show_items/:id/moveexact.json",
    controller: "show_items",
    action: "moveexact"

  post "/show_items/:id/move.json",
    controller: "show_items",
    action: "move"

  get "/s/:uuid-:dims.jpg",
    controller: "images",
    action: "servethumb"

  get "/sf/:uuid.jpg",
    controller: "images",
    action: "servefull"

  # GET /sf/xxxx = show the file
  get "/sf/:uuid",
    controller: "images",
    action: "servefull"

  # GET /sf/xxxx/1 = download the file
  get "/sf/:uuid/:download",
    controller: "images",
    action: "servefull"

  get "/thumbs/:uuid-:dims.jpg",
    controller: "images",
    action: "servethumb"

  # twilio handler
  post "/sms/inbound",
    controller: "sms",
    action: "inbound"

  get "/sms/voice"

  get "uploads/download/:fn" => "uploads#download"
  get "uploads/download/:fn.:discard" => "uploads#download"

  # policy wonking
  get "/about/privacy"
  get "/about/tos"
  get "/about/support"

  get "/about/faq"

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
