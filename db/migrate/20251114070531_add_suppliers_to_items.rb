class AddSuppliersToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :suppliers, :text
  end
end
