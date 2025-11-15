class AddPositionToShipmentPurposes < ActiveRecord::Migration[8.1]
  def change
    add_column :shipment_purposes, :position, :integer, default: 0
    add_index :shipment_purposes, :position

    # 기존 레코드에 position 설정
    reversible do |dir|
      dir.up do
        ShipmentPurpose.reset_column_information
        ShipmentPurpose.order(:id).each.with_index(1) do |purpose, index|
          purpose.update_column(:position, index)
        end
      end
    end
  end
end
