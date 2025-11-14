class Receipt < ApplicationRecord
  belongs_to :item

  validates :receipt_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_expiration_date

  private

  def calculate_expiration_date
    # 제조일이 입력되고, 품목에 shelf_life_days가 설정되어 있으면 유통기한 자동 계산
    if manufacturing_date.present? && item&.shelf_life_days.present?
      self.expiration_date = manufacturing_date + item.shelf_life_days.days
    end
  end
end
