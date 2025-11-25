class CreatePagePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :page_permissions do |t|
      t.string :page_key, null: false
      t.string :name, null: false
      t.string :description
      t.boolean :allowed_for_users, default: true
      t.integer :position, default: 0

      t.timestamps
    end
    add_index :page_permissions, :page_key, unique: true
  end
end
