class ProductionLog < ApplicationRecord
  belongs_to :production_plan
  belongs_to :finished_product

  validates :production_plan, presence: true
  validates :finished_product, presence: true
  validates :production_date, presence: true
end
