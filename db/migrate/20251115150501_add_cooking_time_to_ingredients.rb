class AddCookingTimeToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :cooking_time, :string
  end
end
