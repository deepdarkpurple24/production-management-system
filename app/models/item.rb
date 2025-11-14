class Item < ApplicationRecord
  # 연관관계
  has_many :receipts, dependent: :restrict_with_error

  # 단위 상수
  UNITS = ['Kg', 'g', 'L', 'mL', 'EA'].freeze

  # 유효성 검증
  validates :name, presence: true
  validates :item_code, presence: true, uniqueness: true
  validates :unit, inclusion: { in: UNITS, message: "%{value} is not a valid unit" }, allow_blank: true
  validates :minimum_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :optimal_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :shelf_life_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # 품목코드 자동 생성
  before_validation :generate_item_code, on: :create

  private

  def generate_item_code
    return if item_code.present?

    # 마지막 품목의 코드 번호를 가져와서 +1
    last_item = Item.order(:item_code).last
    if last_item && last_item.item_code =~ /ITEM-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end

    self.item_code = "ITEM-#{next_number.to_s.rjust(4, '0')}"
  end
end
