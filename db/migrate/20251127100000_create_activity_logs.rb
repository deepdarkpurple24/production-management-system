class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false          # create, update, destroy
      t.string :target_type, null: false     # Receipt, Shipment, Item 등
      t.integer :target_id                   # 대상 레코드 ID
      t.string :target_name                  # 대상 레코드 이름 (표시용)
      t.text :details                        # 변경 상세 내용 (JSON)
      t.string :ip_address
      t.string :browser
      t.datetime :performed_at, null: false

      t.timestamps
    end

    add_index :activity_logs, :action
    add_index :activity_logs, :target_type
    add_index :activity_logs, [ :target_type, :target_id ]
    add_index :activity_logs, :performed_at
  end
end
