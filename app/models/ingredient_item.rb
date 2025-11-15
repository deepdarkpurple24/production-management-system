class IngredientItem < ApplicationRecord
  belongs_to :ingredient
  belongs_to :item, optional: true  # 소계 행 또는 재료/기타 선택 시 item이 없음
  belongs_to :referenced_ingredient, class_name: 'Ingredient', foreign_key: 'referenced_ingredient_id', optional: true

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :row_type, inclusion: { in: %w[item subtotal] }
  validates :source_type, inclusion: { in: %w[item ingredient other] }, allow_nil: true
  validate :source_required_for_item_type

  before_create :set_position

  # 표시할 이름 반환
  def display_name
    case source_type
    when 'item'
      item&.name || '품목'
    when 'ingredient'
      referenced_ingredient&.name || '재료'
    when 'other'
      custom_name || '기타'
    else
      item&.name || '품목'
    end
  end

  private

  def source_required_for_item_type
    if row_type == 'item'
      case source_type
      when 'item'
        errors.add(:item, '품목을 선택해주세요') if item_id.blank?
      when 'ingredient'
        errors.add(:referenced_ingredient, '재료를 선택해주세요') if referenced_ingredient_id.blank?
      when 'other'
        errors.add(:custom_name, '기타 재료명을 입력해주세요') if custom_name.blank?
      else
        errors.add(:source_type, '품목 유형을 선택해주세요')
      end
    end
  end

  def set_position
    self.position = ingredient.ingredient_items.maximum(:position).to_i + 1
  end
end
