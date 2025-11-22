class AddIngredientWeightsToProductionLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :production_logs, :ingredient_weights, :json
  end
end
