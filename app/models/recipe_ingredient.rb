# 레시피-재료 연결 - 재료별 중량 및 순서
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :item, optional: true  # 소계 행 또는 재료 선택 시 item이 없음
  belongs_to :referenced_ingredient, class_name: "Ingredient", foreign_key: "referenced_ingredient_id", optional: true
  belongs_to :referenced_recipe, class_name: "Recipe", foreign_key: "referenced_recipe_id", optional: true

  validates :weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :row_type, inclusion: { in: %w[ingredient subtotal] }
  validates :source_type, inclusion: { in: %w[item ingredient recipe] }, allow_nil: true
  validate :source_required_for_ingredient
  validate :no_circular_reference

  before_create :set_position

  # 표시할 이름 반환
  def display_name
    case source_type
    when "item"
      item&.name || "품목"
    when "ingredient"
      referenced_ingredient&.name || "재료"
    when "recipe"
      referenced_recipe&.name || "레시피"
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
      when "recipe"
        errors.add(:referenced_recipe, "레시피를 선택해주세요") if referenced_recipe_id.blank?
      else
        errors.add(:source_type, "재료 유형을 선택해주세요")
      end
    end
  end

  # 순환 참조 방지 (레시피 A가 레시피 B를 참조하고, 레시피 B가 레시피 A를 참조하는 경우 방지)
  def no_circular_reference
    return unless source_type == "recipe" && referenced_recipe_id.present?

    # 자기 자신 참조 방지
    if referenced_recipe_id == recipe_id
      errors.add(:referenced_recipe, "자기 자신을 재료로 사용할 수 없습니다")
      return
    end

    # 순환 참조 체크 (깊이 10까지만 검사)
    if circular_reference?(referenced_recipe_id, [ recipe_id ], 0)
      errors.add(:referenced_recipe, "순환 참조가 발생합니다. 해당 레시피는 이미 현재 레시피를 참조하고 있습니다")
    end
  end

  def circular_reference?(target_recipe_id, visited_ids, depth)
    return false if depth > 10  # 무한 루프 방지

    target_recipe = Recipe.find_by(id: target_recipe_id)
    return false unless target_recipe

    target_recipe.recipe_ingredients.where(source_type: "recipe").each do |ri|
      next unless ri.referenced_recipe_id.present?

      return true if visited_ids.include?(ri.referenced_recipe_id)

      if circular_reference?(ri.referenced_recipe_id, visited_ids + [ ri.referenced_recipe_id ], depth + 1)
        return true
      end
    end

    false
  end

  def set_position
    self.position = recipe.recipe_ingredients.maximum(:position).to_i + 1
  end
end
