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

ActiveRecord::Schema[8.1].define(version: 2025_11_18_154716) do
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
    t.decimal "dough_count", precision: 10, scale: 1
    t.decimal "dough_temp", precision: 10, scale: 1
    t.decimal "fermentation_room_temp", precision: 10, scale: 1
    t.decimal "flour_temp", precision: 10, scale: 1
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

  create_table "production_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "dough_count", precision: 10, scale: 1
    t.decimal "dough_temp", precision: 10, scale: 1
    t.decimal "fermentation_room_temp", precision: 10, scale: 1
    t.integer "finished_product_id", null: false
    t.decimal "flour_temp", precision: 10, scale: 1
    t.decimal "makgeolli_consumption", precision: 10, scale: 1
    t.date "makgeolli_expiry_date"
    t.text "notes"
    t.decimal "porridge_temp", precision: 10, scale: 1
    t.date "production_date"
    t.integer "production_plan_id", null: false
    t.time "production_time"
    t.decimal "refrigeration_room_temp", precision: 10, scale: 1
    t.integer "salt_amount"
    t.decimal "steiva_amount", precision: 10, scale: 1
    t.integer "sugar_amount"
    t.datetime "updated_at", null: false
    t.decimal "water_amount", precision: 10, scale: 1
    t.decimal "water_temp", precision: 10, scale: 1
    t.integer "yeast_amount"
    t.index ["finished_product_id"], name: "index_production_logs_on_finished_product_id"
    t.index ["production_plan_id"], name: "index_production_logs_on_production_plan_id"
  end

  create_table "production_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "finished_product_id", null: false
    t.text "notes"
    t.date "production_date"
    t.decimal "quantity", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["finished_product_id"], name: "index_production_plans_on_finished_product_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiration_date"
    t.integer "item_id", null: false
    t.date "manufacturing_date"
    t.text "notes"
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.date "receipt_date", null: false
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

  create_table "shipment_requesters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_shipment_requesters_on_position"
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

  add_foreign_key "equipment_modes", "equipment_types"
  add_foreign_key "finished_product_recipes", "finished_products"
  add_foreign_key "finished_product_recipes", "recipes", on_delete: :cascade
  add_foreign_key "ingredient_items", "ingredients"
  add_foreign_key "ingredient_items", "items"
  add_foreign_key "production_logs", "finished_products"
  add_foreign_key "production_logs", "production_plans"
  add_foreign_key "production_plans", "finished_products"
  add_foreign_key "receipts", "items"
  add_foreign_key "recipe_equipments", "equipment"
  add_foreign_key "recipe_equipments", "recipes", on_delete: :cascade
  add_foreign_key "recipe_ingredients", "ingredients", column: "referenced_ingredient_id", on_delete: :cascade
  add_foreign_key "recipe_ingredients", "items"
  add_foreign_key "recipe_ingredients", "recipes", on_delete: :cascade
  add_foreign_key "recipe_versions", "recipes", on_delete: :cascade
  add_foreign_key "shipments", "items"
end
