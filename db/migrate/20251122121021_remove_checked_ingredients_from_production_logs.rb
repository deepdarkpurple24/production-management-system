class RemoveCheckedIngredientsFromProductionLogs < ActiveRecord::Migration[8.1]
  def change
    remove_column :production_logs, :checked_ingredients, :json
  end
end
