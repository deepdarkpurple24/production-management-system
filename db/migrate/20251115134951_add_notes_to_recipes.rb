class AddNotesToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :notes, :text
  end
end
