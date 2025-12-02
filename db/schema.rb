# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_02_020407) do
  create_table "activity_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "browser"
    t.datetime "created_at", null: false
    t.text "details"
    t.string "ip_address"
    t.datetime "performed_at", null: false
    t.integer "target_id"
    t.string "target_name"
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["performed_at"], name: "index_activity_logs_on_performed_at"
    t.index ["target_type", "target_id"], name: "index_activity_logs_on_target_type_and_target_id"
    t.index ["target_type"], name: "index_activity_logs_on_target_type"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "authorized_devices", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "authorization_token"
    t.datetime "authorization_token_sent_at"
    t.string "browser"
    t.datetime "created_at", null: false
    t.string "device_name"
    t.string "fingerprint", null: false
    t.datetime "last_used_at"
    t.string "os"
    t.string "status", default: "approved", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["active"], name: "index_authorized_devices_on_active"
    t.index ["authorization_token"], name: "index_authorized_devices_on_authorization_token", unique: true
    t.index ["fingerprint"], name: "index_authorized_devices_on_fingerprint"
    t.index ["status"], name: "index_authorized_devices_on_status"
    t.index ["user_id", "fingerprint"], name: "index_authorized_devices_on_user_id_and_fingerprint"
    t.index ["user_id"], name: "index_authorized_devices_on_user_id"
  end

  create_table "checked_ingredients", force: :cascade do |t|
    t.integer "batch_index", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "expiration_date"
    t.integer "ingredient_index", null: false
    t.integer "opened_item_id"
    t.integer "production_log_id", null: false
    t.integer "receipt_id"
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "used_weight", precision: 10, scale: 2
    t.index ["opened_item_id"], name: "index_checked_ingredients_on_opened_item_id"
    t.index ["production_log_id", "recipe_id", "ingredient_index", "batch_index"], name: "index_checked_ingredients_uniqueness", unique: true
    t.index ["production_log_id"], name: "index_checked_ingredients_on_production_log_id"
    t.index ["receipt_id"], name: "index_checked_ingredients_on_receipt_id"
    t.index ["recipe_id"], name: "index_checked_ingredients_on_recipe_id"
  end

  create_table "equipment", force: :cascade do |t|
    t.decimal "capacity", precision: 10, scale: 2
    t.string "capacity_unit"
    t.datetime "created_at", null: false
    t.integer "equipment_type_id"
    t.string "location"
    t.string "manufacturer"
    t.string "model_number"
    t.string "name"
    t.text "notes"
    t.date "purchase_date"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "equipment_modes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "equipment_type_id", null: false
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["equipment_type_id"], name: "index_equipment_modes_on_equipment_type_id"
  end

  create_table "equipment_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
  end

  create_table "finished_product_recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "finished_product_id", null: false
    t.text "notes"
    t.integer "position"
    t.decimal "quantity"
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.index ["finished_product_id"], name: "index_finished_product_recipes_on_finished_product_id"
    t.index ["recipe_id"], name: "index_finished_product_recipes_on_recipe_id"
  end

  create_table "finished_product_versions", force: :cascade do |t|
    t.text "change_summary"
    t.datetime "changed_at"
    t.string "changed_by"
    t.datetime "created_at", null: false
    t.text "description"
    t.json "finished_product_data"
    t.integer "finished_product_id", null: false
    t.string "name"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.decimal "weight"
    t.string "weight_unit"
    t.index ["finished_product_id", "version_number"], name: "idx_on_finished_product_id_version_number_cb4c6baeb8"
    t.index ["finished_product_id"], name: "index_finished_product_versions_on_finished_product_id"
  end

  create_table "finished_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.text "notes"
    t.datetime "updated_at", null: false
    t.decimal "weight"
    t.string "weight_unit"
  end

  create_table "gijeongddeok_defaults", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "custom_field_defaults", default: {}
    t.decimal "dough_count", precision: 10, scale: 1
    t.decimal "dough_temp", precision: 10, scale: 1
    t.decimal "fermentation_room_temp", precision: 10, scale: 1
    t.decimal "flour_temp", precision: 10, scale: 1
    t.json "half_batch_extra_ingredients", default: []
    t.decimal "makgeolli_consumption", precision: 10, scale: 1
    t.decimal "porridge_temp", precision: 10, scale: 1
    t.decimal "refrigeration_room_temp", precision: 10, scale: 1
    t.integer "salt_amount"
    t.decimal "steiva_amount", precision: 10, scale: 1
    t.integer "sugar_amount"
    t.datetime "updated_at", null: false
    t.decimal "water_amount", precision: 10, scale: 1
    t.decimal "water_temp", precision: 10, scale: 1
    t.integer "yeast_amount"
  end

  create_table "gijeongddeok_field_orders", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "field_name", null: false
    t.string "label", null: false
    t.integer "position", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["field_name"], name: "index_gijeongddeok_field_orders_on_field_name", unique: true
    t.index ["position"], name: "index_gijeongddeok_field_orders_on_position"
  end

  create_table "ingredient_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "custom_name"
    t.integer "ingredient_id", null: false
    t.integer "item_id"
    t.text "notes"
    t.integer "position", default: 0
    t.decimal "quantity", precision: 10, scale: 2
    t.integer "referenced_ingredient_id"
    t.string "row_type", default: "item"
    t.string "source_type"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_ingredient_items_on_ingredient_id"
    t.index ["item_id"], name: "index_ingredient_items_on_item_id"
    t.index ["position"], name: "index_ingredient_items_on_position"
  end

  create_table "ingredient_versions", force: :cascade do |t|
    t.text "change_summary"
    t.datetime "changed_at"
    t.string "changed_by"
    t.integer "cooking_time"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "equipment_mode_id"
    t.integer "equipment_type_id"
    t.json "ingredient_data"
    t.integer "ingredient_id", null: false
    t.string "name"
    t.text "notes"
    t.decimal "production_quantity"
    t.string "production_unit"
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.index ["ingredient_id", "version_number"], name: "index_ingredient_versions_on_ingredient_id_and_version_number"
    t.index ["ingredient_id"], name: "index_ingredient_versions_on_ingredient_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "cooking_time"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "equipment_mode_id"
    t.integer "equipment_type_id"
    t.string "name"
    t.text "notes"
    t.decimal "production_quantity"
    t.string "production_unit"
    t.datetime "updated_at", null: false
  end

  create_table "item_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_item_categories_on_name", unique: true
    t.index ["position"], name: "index_item_categories_on_position"
  end

  create_table "item_versions", force: :cascade do |t|
    t.string "barcode"
    t.string "category"
    t.text "change_summary"
    t.datetime "changed_at"
    t.string "changed_by"
    t.datetime "created_at", null: false
    t.string "item_code"
    t.json "item_data"
    t.integer "item_id", null: false
    t.decimal "minimum_stock"
    t.string "name"
    t.text "notes"
    t.decimal "optimal_stock"
    t.string "stock_unit"
    t.string "storage_location"
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.decimal "weight"
    t.index ["item_id", "version_number"], name: "index_item_versions_on_item_id_and_version_number"
    t.index ["item_id"], name: "index_item_versions_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "barcode"
    t.string "category"
    t.datetime "created_at", null: false
    t.string "item_code", null: false
    t.decimal "minimum_stock", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.decimal "optimal_stock", precision: 10, scale: 2
    t.integer "shelf_life_days"
    t.string "storage_location"
    t.text "suppliers"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.decimal "weight"
    t.string "weight_unit"
    t.index ["item_code"], name: "index_items_on_item_code", unique: true
  end

  create_table "login_histories", force: :cascade do |t|
    t.datetime "attempted_at", null: false
    t.string "browser"
    t.datetime "created_at", null: false
    t.string "device_name"
    t.string "failure_reason"
    t.string "fingerprint"
    t.string "ip_address"
    t.string "os"
    t.boolean "success", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["attempted_at"], name: "index_login_histories_on_attempted_at"
    t.index ["ip_address"], name: "index_login_histories_on_ip_address"
    t.index ["success"], name: "index_login_histories_on_success"
    t.index ["user_id"], name: "index_login_histories_on_user_id"
  end

  create_table "opened_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiration_date"
    t.integer "item_id", null: false
    t.datetime "opened_at", null: false
    t.integer "receipt_id", null: false
    t.decimal "remaining_weight", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["expiration_date"], name: "index_opened_items_on_expiration_date"
    t.index ["item_id", "receipt_id"], name: "index_opened_items_on_item_id_and_receipt_id"
    t.index ["item_id"], name: "index_opened_items_on_item_id"
    t.index ["receipt_id"], name: "index_opened_items_on_receipt_id"
  end

  create_table "packaging_unit_materials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.string "material_type"
    t.text "notes"
    t.integer "packaging_unit_id", null: false
    t.integer "position", default: 0
    t.decimal "quantity_per_unit", precision: 10, scale: 2, default: "1.0"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_packaging_unit_materials_on_item_id"
    t.index ["packaging_unit_id"], name: "index_packaging_unit_materials_on_packaging_unit_id"
  end

  create_table "packaging_units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "finished_product_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.integer "pieces_per_unit", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["finished_product_id"], name: "index_packaging_units_on_finished_product_id"
  end

  create_table "page_permissions", force: :cascade do |t|
    t.boolean "allowed_for_sub_admins", default: false, null: false
    t.boolean "allowed_for_users", default: true
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.string "page_key", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["page_key"], name: "index_page_permissions_on_page_key", unique: true
  end

  create_table "production_logs", force: :cascade do |t|
    t.json "batch_completion_times"
    t.integer "batch_number"
    t.datetime "created_at", null: false
    t.decimal "dough_count", precision: 10, scale: 1
    t.date "dough_date"
    t.decimal "dough_temp", precision: 10, scale: 1
    t.decimal "fermentation_room_temp", precision: 10, scale: 1
    t.integer "finished_product_id", null: false
    t.decimal "flour_temp", precision: 10, scale: 1
    t.json "ingredient_weights"
    t.decimal "makgeolli_consumption", precision: 10, scale: 1
    t.date "makgeolli_expiry_date"
    t.text "notes"
    t.decimal "porridge_temp", precision: 10, scale: 1
    t.date "production_date"
    t.integer "production_plan_id", null: false
    t.time "production_time"
    t.integer "recipe_id"
    t.decimal "refrigeration_room_temp", precision: 10, scale: 1
    t.integer "salt_amount"
    t.string "status", default: "pending"
    t.decimal "steiva_amount", precision: 10, scale: 1
    t.integer "sugar_amount"
    t.datetime "updated_at", null: false
    t.decimal "water_amount", precision: 10, scale: 1
    t.decimal "water_temp", precision: 10, scale: 1
    t.integer "yeast_amount"
    t.index ["finished_product_id"], name: "index_production_logs_on_finished_product_id"
    t.index ["production_plan_id"], name: "index_production_logs_on_production_plan_id"
    t.index ["recipe_id"], name: "index_production_logs_on_recipe_id"
  end

  create_table "production_plan_allocations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "finished_product_id", null: false
    t.integer "production_plan_id", null: false
    t.integer "quantity", default: 0
    t.datetime "updated_at", null: false
    t.index ["finished_product_id"], name: "index_production_plan_allocations_on_finished_product_id"
    t.index ["production_plan_id", "finished_product_id"], name: "idx_plan_allocations_unique", unique: true
    t.index ["production_plan_id"], name: "index_production_plan_allocations_on_production_plan_id"
  end

  create_table "production_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "finished_product_id"
    t.boolean "is_gijeongddeok", default: false
    t.text "notes"
    t.date "production_date"
    t.decimal "quantity", precision: 10, scale: 1
    t.integer "recipe_id"
    t.integer "split_count", default: 1
    t.decimal "split_unit", precision: 3, scale: 1, default: "1.0"
    t.string "unit_type", default: "개"
    t.datetime "updated_at", null: false
    t.index ["finished_product_id"], name: "index_production_plans_on_finished_product_id"
    t.index ["recipe_id"], name: "index_production_plans_on_recipe_id"
  end

  create_table "production_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "defect_count", default: 0
    t.integer "good_quantity", default: 0
    t.text "notes"
    t.boolean "packaging_processed", default: false
    t.integer "packaging_unit_id", null: false
    t.integer "production_plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["packaging_unit_id"], name: "index_production_results_on_packaging_unit_id"
    t.index ["production_plan_id", "packaging_unit_id"], name: "idx_prod_results_plan_unit", unique: true
    t.index ["production_plan_id"], name: "index_production_results_on_production_plan_id"
  end

  create_table "receipt_versions", force: :cascade do |t|
    t.text "change_summary"
    t.datetime "changed_at"
    t.string "changed_by"
    t.datetime "created_at", null: false
    t.date "expiration_date"
    t.integer "item_id"
    t.date "manufacturing_date"
    t.text "notes"
    t.decimal "quantity", precision: 10, scale: 2
    t.json "receipt_data"
    t.date "receipt_date"
    t.integer "receipt_id", null: false
    t.string "requester"
    t.string "supplier"
    t.decimal "unit_price", precision: 10, scale: 2
    t.decimal "unit_weight", precision: 10, scale: 2
    t.string "unit_weight_unit"
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.index ["receipt_id", "version_number"], name: "index_receipt_versions_on_receipt_id_and_version_number"
    t.index ["receipt_id"], name: "index_receipt_versions_on_receipt_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiration_date"
    t.integer "item_id", null: false
    t.date "manufacturing_date"
    t.text "notes"
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.date "receipt_date", null: false
    t.string "requester"
    t.string "supplier"
    t.decimal "unit_price", precision: 10, scale: 2
    t.decimal "unit_weight", precision: 10, scale: 2
    t.string "unit_weight_unit"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_receipts_on_item_id"
    t.index ["receipt_date"], name: "index_receipts_on_receipt_date"
  end

  create_table "recipe_equipments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "equipment_id"
    t.boolean "is_batch_standard", default: false
    t.integer "position"
    t.integer "process_id"
    t.integer "recipe_id", null: false
    t.string "row_type"
    t.datetime "updated_at", null: false
    t.decimal "work_capacity", precision: 10, scale: 2
    t.string "work_capacity_unit"
    t.index ["equipment_id"], name: "index_recipe_equipments_on_equipment_id"
    t.index ["recipe_id"], name: "index_recipe_equipments_on_recipe_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_main", default: false
    t.integer "item_id"
    t.text "notes"
    t.integer "position", default: 0
    t.integer "recipe_id", null: false
    t.integer "referenced_ingredient_id"
    t.string "row_type", default: "ingredient"
    t.string "source_type", default: "item"
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 10, scale: 2
    t.index ["item_id"], name: "index_recipe_ingredients_on_item_id"
    t.index ["position"], name: "index_recipe_ingredients_on_position"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
    t.index ["referenced_ingredient_id"], name: "index_recipe_ingredients_on_referenced_ingredient_id"
    t.index ["source_type"], name: "index_recipe_ingredients_on_source_type"
  end

  create_table "recipe_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
  end

  create_table "recipe_versions", force: :cascade do |t|
    t.text "change_summary"
    t.datetime "changed_at"
    t.string "changed_by"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.text "notes"
    t.json "recipe_data"
    t.integer "recipe_id", null: false
    t.decimal "total_weight"
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.index ["recipe_id", "version_number"], name: "index_recipe_versions_on_recipe_id_and_version_number"
    t.index ["recipe_id"], name: "index_recipe_versions_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.text "notes"
    t.datetime "updated_at", null: false
  end

  create_table "shipment_purposes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_shipment_purposes_on_position"
  end

  create_table "shipment_versions", force: :cascade do |t|
    t.text "change_summary"
    t.datetime "changed_at"
    t.string "changed_by"
    t.datetime "created_at", null: false
    t.integer "item_id"
    t.text "notes"
    t.string "purpose"
    t.decimal "quantity", precision: 10, scale: 2
    t.string "requester"
    t.json "shipment_data"
    t.datetime "shipment_date"
    t.integer "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number"
    t.index ["shipment_id", "version_number"], name: "index_shipment_versions_on_shipment_id_and_version_number"
    t.index ["shipment_id"], name: "index_shipment_versions_on_shipment_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.text "notes"
    t.string "purpose"
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "requester"
    t.datetime "shipment_date"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_shipments_on_item_id"
    t.index ["shipment_date"], name: "index_shipments_on_shipment_date"
  end

  create_table "storage_locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_storage_locations_on_name", unique: true
    t.index ["position"], name: "index_storage_locations_on_position"
  end

  create_table "system_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_system_settings_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.boolean "sub_admin", default: false, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "authorized_devices", "users"
  add_foreign_key "checked_ingredients", "opened_items"
  add_foreign_key "checked_ingredients", "production_logs"
  add_foreign_key "checked_ingredients", "receipts"
  add_foreign_key "checked_ingredients", "recipes"
  add_foreign_key "equipment_modes", "equipment_types"
  add_foreign_key "finished_product_recipes", "finished_products"
  add_foreign_key "finished_product_recipes", "recipes", on_delete: :cascade
  add_foreign_key "finished_product_versions", "finished_products"
  add_foreign_key "ingredient_items", "ingredients"
  add_foreign_key "ingredient_items", "items"
  add_foreign_key "ingredient_versions", "ingredients"
  add_foreign_key "item_versions", "items"
  add_foreign_key "login_histories", "users"
  add_foreign_key "opened_items", "items"
  add_foreign_key "opened_items", "receipts"
  add_foreign_key "packaging_unit_materials", "items"
  add_foreign_key "packaging_unit_materials", "packaging_units"
  add_foreign_key "packaging_units", "finished_products"
  add_foreign_key "production_logs", "finished_products"
  add_foreign_key "production_logs", "production_plans"
  add_foreign_key "production_logs", "recipes"
  add_foreign_key "production_plan_allocations", "finished_products"
  add_foreign_key "production_plan_allocations", "production_plans"
  add_foreign_key "production_plans", "finished_products"
  add_foreign_key "production_plans", "recipes"
  add_foreign_key "production_results", "packaging_units"
  add_foreign_key "production_results", "production_plans"
  add_foreign_key "receipt_versions", "receipts"
  add_foreign_key "receipts", "items"
  add_foreign_key "recipe_equipments", "equipment"
  add_foreign_key "recipe_equipments", "recipes", on_delete: :cascade
  add_foreign_key "recipe_ingredients", "ingredients", column: "referenced_ingredient_id", on_delete: :cascade
  add_foreign_key "recipe_ingredients", "items"
  add_foreign_key "recipe_ingredients", "recipes", on_delete: :cascade
  add_foreign_key "recipe_versions", "recipes", on_delete: :cascade
  add_foreign_key "shipment_versions", "shipments"
  add_foreign_key "shipments", "items"
end
