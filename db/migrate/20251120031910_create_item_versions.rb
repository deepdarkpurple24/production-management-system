class CreateItemVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :item_versions do |t|
      t.references :item, null: false, foreign_key: true
      t.integer :version_number
      t.string :name
      t.string :item_code
      t.string :category
      t.string :storage_location
      t.string :stock_unit
      t.decimal :minimum_stock
      t.decimal :optimal_stock
      t.decimal :weight
      t.string :barcode
      t.string :changed_by
      t.datetime :changed_at
      t.text :change_summary
      t.json :item_data

      t.timestamps
    end

    add_index :item_versions, [:item_id, :version_number]
  end
end
