class CreateOpenedItems < ActiveRecord::Migration[8.1]
  def change
    create_table :opened_items do |t|
      t.references :item, null: false, foreign_key: true
      t.references :receipt, null: false, foreign_key: true
      t.decimal :remaining_weight, precision: 10, scale: 2, null: false, default: 0
      t.date :expiration_date
      t.datetime :opened_at, null: false

      t.timestamps
    end

    add_index :opened_items, [:item_id, :receipt_id]
    add_index :opened_items, :expiration_date
  end
end
