class AddDoughDateToProductionLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :production_logs, :dough_date, :date

    # 기존 데이터: dough_date를 production_date - 1일로 초기화
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE production_logs
          SET dough_date = production_date - INTERVAL '1 day'
          WHERE dough_date IS NULL AND production_date IS NOT NULL
        SQL
      end
    end
  end
end
