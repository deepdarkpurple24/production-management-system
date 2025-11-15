class AddIngredientReferenceToIngredientItems < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredient_items, :referenced_ingredient_id, :integer
    add_column :ingredient_items, :source_type, :string
    add_column :ingredient_items, :custom_name, :string
  end
end
