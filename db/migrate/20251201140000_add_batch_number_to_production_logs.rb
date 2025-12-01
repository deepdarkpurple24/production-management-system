class AddBatchNumberToProductionLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :production_logs, :batch_number, :integer, default: nil
  end
end
