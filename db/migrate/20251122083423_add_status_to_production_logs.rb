class AddStatusToProductionLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :production_logs, :status, :string, default: 'pending'
    add_column :production_logs, :checked_ingredients, :json
  end
end
