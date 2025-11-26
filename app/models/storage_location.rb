# 보관 위치 - 재고 저장 장소
class StorageLocation < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  default_scope { order(position: :asc) }
end
