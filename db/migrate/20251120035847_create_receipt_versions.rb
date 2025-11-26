class CreateReceiptVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_versions do |t|
      t.references :receipt, null: false, foreign_key: true
      t.integer :version_number
      t.integer :item_id
      t.date :receipt_date
      t.decimal :quantity, precision: 10, scale: 2
      t.decimal :unit_price, precision: 10, scale: 2
      t.decimal :unit_weight, precision: 10, scale: 2
      t.string :unit_weight_unit
      t.date :manufacturing_date
      t.date :expiration_date
      t.string :supplier
      t.text :notes
      t.string :changed_by
      t.datetime :changed_at
      t.text :change_summary
      t.json :receipt_data

      t.timestamps
    end

    add_index :receipt_versions, [ :receipt_id, :version_number ]
  end
end
