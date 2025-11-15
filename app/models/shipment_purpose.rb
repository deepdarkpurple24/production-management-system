class ShipmentPurpose < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  default_scope { order(position: :asc) }

  # 새로운 레코드 생성 시 마지막 위치 설정
  before_create :set_position

  private

  def set_position
    self.position = ShipmentPurpose.unscoped.maximum(:position).to_i + 1
  end
end
