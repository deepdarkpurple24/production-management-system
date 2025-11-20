class AddNotesToItemVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :item_versions, :notes, :text
  end
end
