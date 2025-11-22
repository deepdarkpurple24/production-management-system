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

  # 설정 페이지
  get "settings", to: "settings#index", as: "settings"
  get "settings/system", to: "settings#system", as: "settings_system"
  post "settings/purposes", to: "settings#create_purpose", as: "create_shipment_purpose"
  delete "settings/purposes/:id", to: "settings#destroy_purpose", as: "destroy_shipment_purpose"
  patch "settings/purposes/update_positions", to: "settings#update_purpose_positions", as: "update_purpose_positions"
  post "settings/requesters", to: "settings#create_requester", as: "create_shipment_requester"
  delete "settings/requesters/:id", to: "settings#destroy_requester", as: "destroy_shipment_requester"
  patch "settings/requesters/update_positions", to: "settings#update_requester_positions", as: "update_requester_positions"
  post "settings/equipment_types", to: "settings#create_equipment_type", as: "create_equipment_type"
  delete "settings/equipment_types/:id", to: "settings#destroy_equipment_type", as: "destroy_equipment_type"
  patch "settings/equipment_types/update_positions", to: "settings#update_equipment_type_positions", as: "update_equipment_type_positions"
  post "settings/equipment_modes", to: "settings#create_equipment_mode", as: "create_equipment_mode"
  delete "settings/equipment_modes/:id", to: "settings#destroy_equipment_mode", as: "destroy_equipment_mode"
  patch "settings/equipment_modes/update_positions", to: "settings#update_equipment_mode_positions", as: "update_equipment_mode_positions"
  get "settings/equipment_modes/:equipment_type_id", to: "settings#get_equipment_modes", as: "get_equipment_modes"
  post "settings/recipe_processes", to: "settings#create_recipe_process", as: "create_recipe_process"
  delete "settings/recipe_processes/:id", to: "settings#destroy_recipe_process", as: "destroy_recipe_process"
  patch "settings/recipe_processes/update_positions", to: "settings#update_recipe_process_positions", as: "update_recipe_process_positions"
  patch "settings/gijeongddeok_defaults", to: "settings#update_gijeongddeok_defaults", as: "update_gijeongddeok_defaults"
  post "settings/gijeongddeok_fields", to: "settings#create_gijeongddeok_field", as: "create_gijeongddeok_field"
  delete "settings/gijeongddeok_fields/:id", to: "settings#destroy_gijeongddeok_field", as: "destroy_gijeongddeok_field"
  patch "settings/gijeongddeok_fields/update_positions", to: "settings#update_gijeongddeok_field_positions", as: "update_gijeongddeok_field_positions"
  post "settings/item_categories", to: "settings#create_item_category", as: "create_item_category"
  delete "settings/item_categories/:id", to: "settings#destroy_item_category", as: "destroy_item_category"
  patch "settings/item_categories/update_positions", to: "settings#update_item_category_positions", as: "update_item_category_positions"
  post "settings/storage_locations", to: "settings#create_storage_location", as: "create_storage_location"
  delete "settings/storage_locations/:id", to: "settings#destroy_storage_location", as: "destroy_storage_location"
  patch "settings/storage_locations/update_positions", to: "settings#update_storage_location_positions", as: "update_storage_location_positions"

  # 각 모듈 메인 페이지
  get "production", to: "production#index", as: "production"
  get "inventory", to: "inventory#index", as: "inventory"
  get "recipe", to: "recipe#index", as: "recipe_module"
  get "equipment", to: "equipment#index", as: "equipment_module"

  # 각 모듈별 라우트
  namespace :inventory do
    resources :receipts do
      resources :receipt_versions, only: [:index, :destroy]
    end
    resources :shipments do
      resources :shipment_versions, only: [:index, :destroy]
    end
    resources :items do
      collection do
        get :find_by_barcode
      end
      member do
        get :suppliers
        post :add_supplier
      end
      resources :item_versions, only: [:index, :destroy]
    end
    resources :stocks, only: [:index]
    resources :opened_items, only: [:index]
  end

  namespace :production do
    resources :plans
    resources :logs do
      collection do
        post :create_draft
      end
      member do
        patch :update_ingredient_check
        patch :complete_work
      end
    end
  end

  # 레시피 관리
  resources :recipes do
    member do
      patch :update_ingredient_positions
    end
    resources :recipe_versions, only: [:index, :destroy]
  end

  # 재료 관리
  resources :ingredients do
    resources :ingredient_versions, only: [:index, :destroy]
  end

  # 장비 관리
  resources :equipments

  # 완제품 관리
  resources :finished_products do
    resources :finished_product_versions, only: [:index, :destroy]
  end

  # namespace :equipment do
  #   resources :machines
  #   resources :maintenances
  # end
end
