class AddCascadeDeleteToAllRecipeForeignKeys < ActiveRecord::Migration[8.1]
  def change
    # Remove existing foreign keys
    remove_foreign_key :recipe_equipments, :recipes
    remove_foreign_key :recipe_ingredients, :recipes
    remove_foreign_key :finished_product_recipes, :recipes

    # Add new foreign keys with ON DELETE CASCADE
    add_foreign_key :recipe_equipments, :recipes, on_delete: :cascade
    add_foreign_key :recipe_ingredients, :recipes, on_delete: :cascade
    add_foreign_key :finished_product_recipes, :recipes, on_delete: :cascade
  end
end
