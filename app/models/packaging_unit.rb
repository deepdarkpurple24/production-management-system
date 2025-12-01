# 포장 단위 - 완제품별 포장 규격 (30개입, 16개입 등)
class PackagingUnit < ApplicationRecord
  belongs_to :finished_product
  has_many :packaging_unit_materials, -> { order(position: :asc) }, dependent: :destroy

  accepts_nested_attributes_for :packaging_unit_materials, allow_destroy: true

  validates :name, presence: true
  validates :pieces_per_unit, presence: true, numericality: { greater_than: 0 }

  default_scope { order(position: :asc) }

  # 특정 박스 수에 대해 필요한 포장재 계산
  def calculate_materials_for_boxes(box_count)
    packaging_unit_materials.includes(:item).map do |pum|
      {
        item: pum.item,
        material_type: pum.material_type,
        quantity: pum.quantity_per_unit * box_count
      }
    end
  end
end
