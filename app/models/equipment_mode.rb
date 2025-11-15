class EquipmentMode < ApplicationRecord
  belongs_to :equipment_type

  validates :name, presence: true
  validates :name, uniqueness: { scope: :equipment_type_id, message: "이 장비 구분에 이미 같은 이름의 모드가 있습니다" }

  before_create :set_position

  default_scope { order(position: :asc) }

  private

  def set_position
    self.position ||= (equipment_type.equipment_modes.unscoped.maximum(:position) || 0) + 1
  end
end
