class AddBatchCompletionTimesToProductionLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :production_logs, :batch_completion_times, :json
  end
end
