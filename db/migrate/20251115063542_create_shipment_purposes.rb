class CreateShipmentPurposes < ActiveRecord::Migration[8.1]
  def change
    create_table :shipment_purposes do |t|
      t.string :name

      t.timestamps
    end
  end
end
