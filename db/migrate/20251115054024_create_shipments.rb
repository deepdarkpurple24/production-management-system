class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :item, null: false, foreign_key: true
      t.date :shipment_date, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :destination
      t.string :purpose
      t.text :notes

      t.timestamps
    end

    add_index :shipments, :shipment_date
  end
end
