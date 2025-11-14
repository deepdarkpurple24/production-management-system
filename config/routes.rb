Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # 각 모듈 메인 페이지
  get "production", to: "production#index", as: "production"
  get "inventory", to: "inventory#index", as: "inventory"
  get "recipe", to: "recipe#index", as: "recipe"
  get "equipment", to: "equipment#index", as: "equipment"

  # 각 모듈별 라우트 (추후 구현)
  # namespace :production do
  #   resources :plans
  #   resources :logs
  # end

  # namespace :inventory do
  #   resources :receipts
  #   resources :opened_items
  #   resources :shipments
  #   resources :stocks
  #   resources :items
  # end

  # namespace :recipe do
  #   resources :recipes
  #   resources :products
  # end

  # namespace :equipment do
  #   resources :machines
  #   resources :maintenances
  # end
end
