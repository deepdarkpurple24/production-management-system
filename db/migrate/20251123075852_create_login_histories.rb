class CreateLoginHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :login_histories do |t|
      t.references :user, foreign_key: true
      t.string :fingerprint
      t.string :ip_address
      t.string :browser
      t.string :os
      t.string :device_name
      t.boolean :success, null: false
      t.string :failure_reason
      t.datetime :attempted_at, null: false

      t.timestamps
    end

    add_index :login_histories, :attempted_at
    add_index :login_histories, :success
    add_index :login_histories, :ip_address
  end
end
