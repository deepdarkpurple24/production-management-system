# 레시피-재료 연결 - 재료별 중량 및 순서
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :item, optional: true  # 소계 행 또는 재료 선택 시 item이 없음
  belongs_to :referenced_ingredient, class_name: "Ingredient", foreign_key: "referenced_ingredient_id", optional: true

  validates :weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :row_type, inclusion: { in: %w[ingredient subtotal] }
  validates :source_type, inclusion: { in: %w[item ingredient] }, allow_nil: true
  validate :source_required_for_ingredient

  before_create :set_position

  # 표시할 이름 반환
  def display_name
    case source_type
    when "item"
      item&.name || "품목"
    when "ingredient"
      referenced_ingredient&.name || "재료"
    else
      item&.name || "품목"
    end
  end

  # 베이커리% 계산 (주재료 기준)
  def bakery_percentage
    return nil if row_type == "subtotal"
    main_weight = recipe.main_ingredient_weight
    return nil if main_weight.zero?
    (weight / main_weight * 100).round(2)
  end

  # 백분율 계산 (총중량 기준)
  def percentage
    return nil if row_type == "subtotal"
    total = recipe.total_weight
    return nil if total.zero?
    (weight / total * 100).round(2)
  end

  private

  def source_required_for_ingredient
    if row_type == "ingredient"
      case source_type
      when "item"
        errors.add(:item, "품목을 선택해주세요") if item_id.blank?
      when "ingredient"
        errors.add(:referenced_ingredient, "재료를 선택해주세요") if referenced_ingredient_id.blank?
      else
        errors.add(:source_type, "재료 유형을 선택해주세요")
      end
    end
  end

  def set_position
    self.position = recipe.recipe_ingredients.maximum(:position).to_i + 1
  end
end
