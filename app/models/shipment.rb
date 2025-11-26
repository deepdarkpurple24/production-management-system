# 출고 내역 - 품목 출고 기록 및 재고 차감
class Shipment < ApplicationRecord
  belongs_to :item
  has_many :shipment_versions, -> { order(version_number: :desc) }, dependent: :destroy

  validates :shipment_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :check_available_stock

  before_update :create_version_snapshot

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

  def create_version_snapshot
    return unless changed?

    version_num = shipment_versions.maximum(:version_number).to_i + 1
    change_list = []

    # 기본 정보 변경 감지
    if item_id_changed?
      change_list << "품목 변경"
    end

    if shipment_date_changed?
      change_list << "출고일: '#{shipment_date_was}' → '#{shipment_date}'"
    end

    if quantity_changed?
      change_list << "수량: '#{quantity_was}' → '#{quantity}'"
    end

    if purpose_changed?
      change_list << "목적: '#{purpose_was}' → '#{purpose}'"
    end

    if requester_changed?
      change_list << "요청자: '#{requester_was}' → '#{requester}'"
    end

    if notes_changed?
      change_list << "비고 변경"
    end

    # 변경사항이 없으면 기본 메시지
    change_list << "출고 정보 수정" if change_list.empty?

    # 이전 데이터 스냅샷 저장 (변경 전 데이터 저장)
    shipment_versions.create!(
      version_number: version_num,
      item_id: item_id_was || item_id,
      shipment_date: shipment_date_was || shipment_date,
      quantity: quantity_was || quantity,
      purpose: purpose_was || purpose,
      requester: requester_was || requester,
      notes: notes_was || notes,
      changed_by: "System",
      changed_at: Time.current,
      change_summary: change_list.join(", "),
      shipment_data: {
        item_name: item&.name
      }
    )
  end
end
