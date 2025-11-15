class AddUnitToIngredientItems < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredient_items, :unit, :string
  end
end
