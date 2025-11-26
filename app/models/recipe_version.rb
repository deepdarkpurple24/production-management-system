# 레시피 버전 관리 - 변경 이력 추적
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
