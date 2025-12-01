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

  # 삭제 전 개봉품 중량 복원
  before_destroy :restore_opened_item_weight

  private

  def restore_opened_item_weight
    if opened_item.present? && used_weight.present? && used_weight > 0
      opened_item.restore_weight(used_weight)
      Rails.logger.info "CheckedIngredient##{id} 삭제: 개봉품##{opened_item.id}에 #{used_weight}g 복원"
    end
  end
end
