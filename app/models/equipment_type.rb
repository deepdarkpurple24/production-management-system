class EquipmentType < ApplicationRecord
  has_many :equipment_modes, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  before_create :set_position

  default_scope { order(position: :asc) }

  private

  def set_position
    self.position ||= (EquipmentType.unscoped.maximum(:position) || 0) + 1
  end
end
