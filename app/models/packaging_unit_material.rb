# 포장 단위별 사용 포장재
class PackagingUnitMaterial < ApplicationRecord
  belongs_to :packaging_unit
  belongs_to :item  # 포장재 품목

  validates :item_id, presence: true
  validates :quantity_per_unit, presence: true, numericality: { greater_than: 0 }

  # 포장재 유형 목록
  MATERIAL_TYPES = %w[내포장재 외포장재 기타].freeze

  default_scope { order(position: :asc) }
end
