class IngredientVersion < ApplicationRecord
  belongs_to :ingredient

  validates :version_number, presence: true
  validates :changed_at, presence: true

  def ingredient_items_data
    ingredient_data&.dig("ingredient_items") || []
  end
end
