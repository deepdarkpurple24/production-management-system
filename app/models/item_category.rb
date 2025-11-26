# 품목 카테고리 - 품목 분류 체계
class ItemCategory < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  default_scope { order(position: :asc) }
end
