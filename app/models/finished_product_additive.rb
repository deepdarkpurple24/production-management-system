class FinishedProductAdditive < ApplicationRecord
  belongs_to :finished_product
  belongs_to :item, class_name: "Inventory::Item", foreign_key: "item_id"

  validates :weight, presence: true, numericality: { greater_than: 0 }
end
