class ItemVersion < ApplicationRecord
  belongs_to :item

  validates :version_number, presence: true
  validates :changed_at, presence: true

  def suppliers_data
    item_data&.dig("suppliers") || []
  end

  def weight_unit_data
    item_data&.dig("weight_unit")
  end
end
