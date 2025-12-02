Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # Admin routes
  namespace :admin do
    resources :users do
      resources :authorized_devices, only: [ :create, :destroy ] do
        member do
          patch :toggle_active
        end
      end
    end
    resources :login_histories, only: [ :index ]
    resources :activity_logs, only: [ :index ]

    # 관리자 설정 페이지
    get "settings", to: "settings#index", as: "settings"
    patch "settings/system", to: "settings#update_system", as: "settings_update_system"

    # 출고 목적 관리
    post "settings/purposes", to: "settings#create_purpose", as: "settings_create_purpose"
    delete "settings/purposes/:id", to: "settings#destroy_purpose", as: "settings_destroy_purpose"
    patch "settings/purposes/update_positions", to: "settings#update_purpose_positions", as: "settings_update_purpose_positions"

    # 장비 구분 관리
    post "settings/equipment_types", to: "settings#create_equipment_type", as: "settings_create_equipment_type"
    delete "settings/equipment_types/:id", to: "settings#destroy_equipment_type", as: "settings_destroy_equipment_type"
    patch "settings/equipment_types/update_positions", to: "settings#update_equipment_type_positions", as: "settings_update_equipment_type_positions"

    # 장비 모드 관리
    post "settings/equipment_modes", to: "settings#create_equipment_mode", as: "settings_create_equipment_mode"
    patch "settings/equipment_modes/update_positions", to: "settings#update_equipment_mode_positions", as: "settings_update_equipment_mode_positions"
    get "settings/equipment_modes/:equipment_type_id", to: "settings#get_equipment_modes", as: "settings_get_equipment_modes"
    delete "settings/equipment_modes/:id", to: "settings#destroy_equipment_mode", as: "settings_destroy_equipment_mode"

    # 공정 관리
    post "settings/recipe_processes", to: "settings#create_recipe_process", as: "settings_create_recipe_process"
    delete "settings/recipe_processes/:id", to: "settings#destroy_recipe_process", as: "settings_destroy_recipe_process"
    patch "settings/recipe_processes/update_positions", to: "settings#update_recipe_process_positions", as: "settings_update_recipe_process_positions"

    # 기정떡 기본값 관리
    patch "settings/gijeongddeok_defaults", to: "settings#update_gijeongddeok_defaults", as: "settings_update_gijeongddeok_defaults"
    patch "settings/gijeongddeok_default_product", to: "settings#update_gijeongddeok_default_product", as: "settings_update_gijeongddeok_default_product"
    patch "settings/gijeongddeok_default_products", to: "settings#update_gijeongddeok_default_products", as: "settings_update_gijeongddeok_default_products"
    post "settings/gijeongddeok_fields", to: "settings#create_gijeongddeok_field", as: "settings_create_gijeongddeok_field"
    delete "settings/gijeongddeok_fields/:id", to: "settings#destroy_gijeongddeok_field", as: "settings_destroy_gijeongddeok_field"
    patch "settings/gijeongddeok_fields/update_positions", to: "settings#update_gijeongddeok_field_positions", as: "settings_update_gijeongddeok_field_positions"
    patch "settings/half_batch_ingredients", to: "settings#update_half_batch_ingredients", as: "settings_update_half_batch_ingredients"

    # 품목 카테고리 관리
    post "settings/item_categories", to: "settings#create_item_category", as: "settings_create_item_category"
    delete "settings/item_categories/:id", to: "settings#destroy_item_category", as: "settings_destroy_item_category"
    patch "settings/item_categories/update_positions", to: "settings#update_item_category_positions", as: "settings_update_item_category_positions"

    # 보관위치 관리
    post "settings/storage_locations", to: "settings#create_storage_location", as: "settings_create_storage_location"
    delete "settings/storage_locations/:id", to: "settings#destroy_storage_location", as: "settings_destroy_storage_location"
    patch "settings/storage_locations/update_positions", to: "settings#update_storage_location_positions", as: "settings_update_storage_location_positions"

    # 페이지 권한 관리
    patch "settings/page_permissions/:id", to: "settings#update_page_permission", as: "settings_update_page_permission"
    patch "settings/page_permissions", to: "settings#update_page_permissions_batch", as: "settings_update_page_permissions_batch"
  end

  # Device authorization routes
  resources :device_authorizations, only: [ :new ] do
    collection do
      post :send_email
      post :request_admin
      get :approve
    end
  end

  # User profile and device management routes
  namespace :my do
    resource :password, only: [ :show, :update ]
    resources :devices, only: [ :index, :update, :destroy ]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # 기존 설정 페이지 리다이렉트 (관리자 설정으로 이동)
  get "settings", to: redirect("/admin/settings")
  get "settings/system", to: redirect("/admin/settings")

  # 장비 모드 API (재료 등록 등에서 사용)
  get "settings/equipment_modes/:equipment_type_id", to: "settings#get_equipment_modes", as: "settings_get_equipment_modes"

  # 각 모듈 메인 페이지
  get "production", to: "production#index", as: "production"
  get "inventory", to: "inventory#index", as: "inventory"
  get "recipe", to: "recipe#index", as: "recipe_module"
  get "equipment", to: "equipment#index", as: "equipment_module"

  # 각 모듈별 라우트
  namespace :inventory do
    resources :receipts do
      resources :receipt_versions, only: [ :index, :destroy ]
    end
    resources :shipments do
      resources :shipment_versions, only: [ :index, :destroy ]
    end
    resources :items do
      collection do
        get :find_by_barcode
        get :search_by_name
      end
      member do
        get :suppliers
        post :add_supplier
      end
      resources :item_versions, only: [ :index, :destroy ]
    end
    resources :stocks, only: [ :index ]
    resources :opened_items, only: [ :index ]
  end

  namespace :production do
    resources :plans do
      collection do
        post :batch_create
      end
      resources :results, only: [ :create, :update, :destroy ] do
        collection do
          post :process_packaging
        end
      end
    end
    resources :logs do
      collection do
        post :create_draft
      end
      member do
        patch :update_ingredient_check
        patch :complete_work
        patch :update_batch_time
      end
    end
    # 생산품관리 (별도 페이지)
    resources :product_management, only: [ :index ]
  end

  # 레시피 관리
  resources :recipes do
    member do
      patch :update_ingredient_positions
    end
    resources :recipe_versions, only: [ :index, :destroy ]
  end

  # 재료 관리
  resources :ingredients do
    resources :ingredient_versions, only: [ :index, :destroy ]
  end

  # 장비 관리
  resources :equipments

  # 완제품 관리
  resources :finished_products do
    resources :finished_product_versions, only: [ :index, :destroy ]
  end

  # namespace :equipment do
  #   resources :machines
  #   resources :maintenances
  # end
end
