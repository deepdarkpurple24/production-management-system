# 재료 사용 기록 - 생산일지와 재고 연결
class CheckedIngredient < ApplicationRecord
  belongs_to :production_log
  belongs_to :recipe
  belongs_to :receipt, optional: true
  belongs_to :opened_item, optional: true

  validates :production_log, presence: true
  validates :recipe, presence: true
  validates :ingredient_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :batch_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :ingredient_index, uniqueness: { scope: [ :production_log_id, :recipe_id, :batch_index ] }
end
