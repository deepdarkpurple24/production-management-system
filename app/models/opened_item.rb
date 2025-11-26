class OpenedItem < ApplicationRecord
  belongs_to :item
  belongs_to :receipt
  has_many :checked_ingredients, dependent: :nullify

  validates :remaining_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :opened_at, presence: true

  # 유통기한 순으로 정렬 (짧은 것부터)
  scope :by_expiration, -> { order(expiration_date: :asc, created_at: :asc) }
  # 남은 중량이 있는 것만
  scope :available, -> { where("remaining_weight > 0") }

  # 중량 차감
  def deduct_weight(amount)
    update(remaining_weight: remaining_weight - amount)
  end

  # 중량 복원
  def restore_weight(amount)
    update(remaining_weight: remaining_weight + amount)
  end

  # 완전히 소진되었는지 확인
  def depleted?
    remaining_weight <= 0
  end
end
