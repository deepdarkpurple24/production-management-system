# 생산 계획 - 일자별 생산 스케줄
class ProductionPlan < ApplicationRecord
  belongs_to :finished_product
  has_many :production_logs, dependent: :destroy
  has_many :production_results, dependent: :destroy

  validates :finished_product, presence: true
  validates :production_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  # 사용 가능한 포장 단위 (완제품에 등록된 포장 단위)
  def available_packaging_units
    finished_product.packaging_units
  end

  # 총 생산 완제품 수량 (박스)
  def total_good_boxes
    production_results.sum(:good_quantity)
  end

  # 총 불량 개수
  def total_defect_count
    production_results.sum(:defect_count)
  end

  # 총 생산 완제품 개수
  def total_good_pieces
    production_results.includes(:packaging_unit).sum { |r| r.good_pieces }
  end
end
