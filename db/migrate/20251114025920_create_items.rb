class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :item_code, null: false
      t.string :name, null: false
      t.string :category
      t.string :unit
      t.decimal :minimum_stock, precision: 10, scale: 2
      t.decimal :optimal_stock, precision: 10, scale: 2
      t.string :storage_location
      t.integer :shelf_life_days, comment: "제조일로부터 유통기한(일)"
      t.text :notes

      t.timestamps
    end

    add_index :items, :item_code, unique: true
  end
end
