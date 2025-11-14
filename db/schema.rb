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

ActiveRecord::Schema[8.1].define(version: 2025_11_14_031601) do
  create_table "items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "item_code", null: false
    t.decimal "minimum_stock", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.decimal "optimal_stock", precision: 10, scale: 2
    t.integer "shelf_life_days"
    t.string "storage_location"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_items_on_item_code", unique: true
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
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_receipts_on_item_id"
    t.index ["receipt_date"], name: "index_receipts_on_receipt_date"
  end

  add_foreign_key "receipts", "items"
end
