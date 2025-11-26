# 완제품-레시피 연결 - 레시피별 수량
class FinishedProductRecipe < ApplicationRecord
  belongs_to :finished_product
  belongs_to :recipe

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_create :set_position

  private

  def set_position
    self.position = finished_product.finished_product_recipes.maximum(:position).to_i + 1
  end
end
