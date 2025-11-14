class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :item, null: false, foreign_key: true
      t.date :receipt_date, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.date :manufacturing_date
      t.date :expiration_date
      t.decimal :unit_price, precision: 10, scale: 2
      t.string :supplier
      t.text :notes

      t.timestamps
    end

    add_index :receipts, :receipt_date
  end
end
