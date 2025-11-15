class AddOnDeleteCascadeToRecipeVersions < ActiveRecord::Migration[8.1]
  def change
    # Remove existing foreign key
    remove_foreign_key :recipe_versions, :recipes

    # Add new foreign key with ON DELETE CASCADE
    add_foreign_key :recipe_versions, :recipes, on_delete: :cascade
  end
end
