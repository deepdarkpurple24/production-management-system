class ProductionPlan < ApplicationRecord
  belongs_to :finished_product
  has_many :production_logs, dependent: :destroy

  validates :finished_product, presence: true
  validates :production_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
