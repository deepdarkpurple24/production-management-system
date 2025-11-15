class AddPositionToShipmentRequesters < ActiveRecord::Migration[8.1]
  def change
    add_column :shipment_requesters, :position, :integer, default: 0
    add_index :shipment_requesters, :position

    # 기존 레코드에 position 설정
    reversible do |dir|
      dir.up do
        ShipmentRequester.reset_column_information
        ShipmentRequester.order(:id).each.with_index(1) do |requester, index|
          requester.update_column(:position, index)
        end
      end
    end
  end
end
