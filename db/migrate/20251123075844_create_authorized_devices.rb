class CreateAuthorizedDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :authorized_devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :fingerprint, null: false
      t.string :device_name
      t.string :browser
      t.string :os
      t.boolean :active, default: true, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :authorized_devices, [ :user_id, :fingerprint ]
    add_index :authorized_devices, :fingerprint
    add_index :authorized_devices, :active
  end
end
