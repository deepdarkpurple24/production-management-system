class FinishedProductAdditive < ApplicationRecord
  belongs_to :finished_product
  belongs_to :item

  validates :weight, presence: true, numericality: { greater_than: 0 }
end
