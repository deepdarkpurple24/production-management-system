# 생산 계획 - 레시피 기반 생산 스케줄
class ProductionPlan < ApplicationRecord
  belongs_to :recipe, optional: true
  belongs_to :finished_product, optional: true  # 레거시 호환
  has_many :production_logs, dependent: :destroy
  has_many :production_results, dependent: :destroy
  has_many :production_plan_allocations, dependent: :destroy
  has_many :allocated_finished_products, through: :production_plan_allocations, source: :finished_product

  accepts_nested_attributes_for :production_plan_allocations, allow_destroy: true

  validates :production_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :must_have_recipe_or_finished_product

  # 레시피 기반인지 확인
  def recipe_based?
    recipe_id.present?
  end

  # 단위 타입 (개/통)
  def unit_label
    unit_type.presence || '개'
  end

  # 레시피 총 중량 계산 (g)
  def total_recipe_weight
    return 0 unless recipe
    recipe.total_weight * quantity
  end

  # 배분된 완제품 총 중량 계산 (g)
  def allocated_weight
    production_plan_allocations.includes(:finished_product).sum do |allocation|
      (allocation.finished_product.weight || 0) * allocation.quantity
    end
  end

  # 잔여 중량 계산 (g) - 기본 완제품용
  def remaining_weight
    total_recipe_weight - allocated_weight
  end

  # 사용 가능한 포장 단위 (완제품에 등록된 포장 단위)
  def available_packaging_units
    finished_product&.packaging_units || []
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

  private

  def must_have_recipe_or_finished_product
    unless recipe_id.present? || finished_product_id.present?
      errors.add(:base, "레시피 또는 완제품을 선택해야 합니다.")
    end
  end
end
