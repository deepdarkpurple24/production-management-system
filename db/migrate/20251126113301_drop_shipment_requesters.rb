class DropShipmentRequesters < ActiveRecord::Migration[8.1]
  def change
    drop_table :shipment_requesters, if_exists: true
  end
end
