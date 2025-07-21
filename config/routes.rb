Rails.application.routes.draw do
  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    
    resource :profile, only: [:edit, :update]
    resource :password, only: [:edit, :update]
    resource :site_settings, only: [:show, :update], path: "site-settings"
    post "site_settings/upload_image", to: "site_settings#upload_image"
    
    resources :admins, only: [:index, :show, :new, :create, :destroy] do
      member do
        get :confirm_delete
        post :process_delete
      end
    end
    
    resources :articles, only: [:index, :new, :create, :edit, :update, :destroy] do
      collection do
        get :drafts
      end
    end
    post "articles/preview", to: "articles#preview"
    post "articles/upload_image", to: "articles#upload_image"
  end
  root "articles#index"
  resources :articles, path: "article", only: [:index, :show]
  
  get "feed", to: "articles#feed", defaults: { format: 'rss' }
  get "archive/:year", to: "articles#archive_year", as: :archive_year
  get "archive/:year/:month", to: "articles#archive_month", as: :archive_month
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
