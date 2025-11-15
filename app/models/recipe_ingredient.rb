class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :item, optional: true  # 소계 행일 때는 item이 없음

  validates :weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :row_type, inclusion: { in: %w[ingredient subtotal] }
  validate :item_required_for_ingredient

  before_create :set_position

  # 베이커리% 계산 (주재료 기준)
  def bakery_percentage
    return nil if row_type == 'subtotal'
    main_weight = recipe.main_ingredient_weight
    return nil if main_weight.zero?
    (weight / main_weight * 100).round(2)
  end

  # 백분율 계산 (총중량 기준)
  def percentage
    return nil if row_type == 'subtotal'
    total = recipe.total_weight
    return nil if total.zero?
    (weight / total * 100).round(2)
  end

  private

  def item_required_for_ingredient
    if row_type == 'ingredient' && item_id.blank?
      errors.add(:item, '재료를 선택해주세요')
    end
  end

  def set_position
    self.position = recipe.recipe_ingredients.maximum(:position).to_i + 1
  end
end
