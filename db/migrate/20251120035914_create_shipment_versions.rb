class CreateShipmentVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :shipment_versions do |t|
      t.references :shipment, null: false, foreign_key: true
      t.integer :version_number
      t.integer :item_id
      t.datetime :shipment_date
      t.decimal :quantity, precision: 10, scale: 2
      t.string :purpose
      t.string :requester
      t.text :notes
      t.string :changed_by
      t.datetime :changed_at
      t.text :change_summary
      t.json :shipment_data

      t.timestamps
    end

    add_index :shipment_versions, [:shipment_id, :version_number]
  end
end
