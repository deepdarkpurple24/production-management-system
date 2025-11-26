class AddAllowedForSubAdminsToPagePermissions < ActiveRecord::Migration[8.1]
  def change
    add_column :page_permissions, :allowed_for_sub_admins, :boolean, default: false, null: false
  end
end
