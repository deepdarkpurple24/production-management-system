class UpdateShipmentsForEnhancements < ActiveRecord::Migration[8.1]
  def change
    # shipment_date를 datetime으로 변경
    change_column :shipments, :shipment_date, :datetime

    # destination 컬럼 제거
    remove_column :shipments, :destination, :string

    # requester 컬럼 추가
    add_column :shipments, :requester, :string
  end
end
