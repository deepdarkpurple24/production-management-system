class AddRecipeIdToProductionLogs < ActiveRecord::Migration[8.1]
  def change
    add_reference :production_logs, :recipe, null: true, foreign_key: true
  end
end
