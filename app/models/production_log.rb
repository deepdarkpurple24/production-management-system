# 반죽일지 - 실제 생산 기록 및 품질 데이터
class ProductionLog < ApplicationRecord
  belongs_to :production_plan
  belongs_to :finished_product
  belongs_to :recipe, optional: true
  has_many :checked_ingredients, dependent: :destroy

  validates :production_plan, presence: true
  validates :finished_product, presence: true
  validates :production_date, presence: true
end
