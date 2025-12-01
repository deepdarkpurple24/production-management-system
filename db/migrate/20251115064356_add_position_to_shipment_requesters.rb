class AddPositionToShipmentRequesters < ActiveRecord::Migration[8.1]
  def change
    add_column :shipment_requesters, :position, :integer, default: 0
    add_index :shipment_requesters, :position

    # 기존 레코드에 position 설정 (raw SQL 사용 - 모델 참조 없이)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE shipment_requesters
          SET position = (
            SELECT COUNT(*) FROM shipment_requesters sr2 WHERE sr2.id <= shipment_requesters.id
          )
        SQL
      end
    end
  end
end
