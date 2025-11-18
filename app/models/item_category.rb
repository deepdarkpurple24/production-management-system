class ItemCategory < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  default_scope { order(position: :asc) }
end
