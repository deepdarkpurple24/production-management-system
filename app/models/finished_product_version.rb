class FinishedProductVersion < ApplicationRecord
  belongs_to :finished_product

  validates :version_number, presence: true
  validates :changed_at, presence: true

  def finished_product_recipes_data
    finished_product_data&.dig("finished_product_recipes") || []
  end
end
