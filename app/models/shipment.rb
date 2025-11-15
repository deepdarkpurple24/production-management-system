class Shipment < ApplicationRecord
  belongs_to :item

  validates :shipment_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :check_available_stock

  private

  def check_available_stock
    return unless item && quantity

    # 현재 재고 계산 (수정 시에는 이 출고 건 제외)
    total_receipts = item.receipts.sum(:quantity)
    total_shipments = item.shipments.where.not(id: id).sum(:quantity)
    available_stock = total_receipts - total_shipments

    if available_stock <= 0
      errors.add(:base, "#{item.name}의 재고가 없습니다. 먼저 입고를 진행해주세요.")
    elsif quantity > available_stock
      errors.add(:quantity, "재고가 부족합니다. 현재 재고: #{available_stock}#{item.unit.present? ? item.unit : '개'}")
    end
  end
end
