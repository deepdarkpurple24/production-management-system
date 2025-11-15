class RecipeVersion < ApplicationRecord
  belongs_to :recipe

  validates :version_number, presence: true
  validates :changed_at, presence: true

  def ingredients_data
    recipe_data&.dig("ingredients") || []
  end

  def equipments_data
    recipe_data&.dig("equipments") || []
  end
end
