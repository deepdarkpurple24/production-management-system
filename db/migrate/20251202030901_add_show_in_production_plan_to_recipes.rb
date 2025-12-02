class AddShowInProductionPlanToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :show_in_production_plan, :boolean, default: true, null: false
  end
end
