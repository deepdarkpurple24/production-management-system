# 생산 실적 - 포장 단위별 완제품/불량 수량 기록
class ProductionResult < ApplicationRecord
  belongs_to :production_plan
  belongs_to :packaging_unit

  validates :good_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :defect_count, numericality: { greater_than_or_equal_to: 0 }
  validates :packaging_unit_id, uniqueness: { scope: :production_plan_id, message: "이 포장 단위는 이미 등록되어 있습니다" }

  # 완제품 개수 (박스 × 개수/박스)
  def good_pieces
    good_quantity * packaging_unit.pieces_per_unit
  end

  # 총 생산 개수 (완제품 + 불량)
  def total_pieces
    good_pieces + defect_count
  end

  # 필요한 포장재 계산
  def calculate_required_materials
    packaging_unit.calculate_materials_for_boxes(good_quantity)
  end

  # 포장재 출고 처리
  def process_packaging_shipment!
    return if packaging_processed?
    return if good_quantity.zero?

    materials = calculate_required_materials
    materials.each do |material|
      # TODO: 출고 처리 로직 구현
      # Inventory::Shipment 또는 유사한 방식으로 처리
    end

    update!(packaging_processed: true)
  end
end
