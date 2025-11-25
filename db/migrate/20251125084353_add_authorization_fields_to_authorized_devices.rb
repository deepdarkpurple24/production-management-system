class AddAuthorizationFieldsToAuthorizedDevices < ActiveRecord::Migration[8.1]
  def change
    add_column :authorized_devices, :authorization_token, :string
    add_column :authorized_devices, :authorization_token_sent_at, :datetime
    add_column :authorized_devices, :status, :string, default: 'approved', null: false

    add_index :authorized_devices, :authorization_token, unique: true
    add_index :authorized_devices, :status
  end
end
