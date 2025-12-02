# 생산계획 완제품 배분 - 반죽에서 파생되는 완제품 수량
class ProductionPlanAllocation < ApplicationRecord
  belongs_to :production_plan
  belongs_to :finished_product

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
