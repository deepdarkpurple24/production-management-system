class Ingredient < ApplicationRecord
  belongs_to :equipment_type, optional: true
  belongs_to :equipment_mode, optional: true
  has_many :ingredient_items, -> { order(position: :asc) }, dependent: :destroy
  has_many :items, through: :ingredient_items

  accepts_nested_attributes_for :ingredient_items, allow_destroy: true

  validates :name, presence: true

  # 총 수량 계산 (소계 제외)
  def total_quantity
    ingredient_items.where(row_type: 'item').sum(:quantity)
  end

  # 소계 전 수량 계산
  def subtotal_quantity
    subtotal_item = ingredient_items.find_by(row_type: 'subtotal')
    if subtotal_item
      ingredient_items.where(row_type: 'item')
                      .where('position < ?', subtotal_item.position)
                      .sum(:quantity)
    else
      total_quantity
    end
  end
end
