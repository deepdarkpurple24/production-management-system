class AddCustomFieldDefaultsToGijeongddeokDefaults < ActiveRecord::Migration[8.1]
  def change
    add_column :gijeongddeok_defaults, :custom_field_defaults, :json, default: {}
  end
end
