class FinishedProduct < ApplicationRecord
  has_many :finished_product_recipes, -> { order(position: :asc) }, dependent: :destroy
  has_many :recipes, through: :finished_product_recipes
  has_many :production_plans, dependent: :destroy
  has_many :production_logs, dependent: :destroy

  accepts_nested_attributes_for :finished_product_recipes, allow_destroy: true

  validates :name, presence: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
end
