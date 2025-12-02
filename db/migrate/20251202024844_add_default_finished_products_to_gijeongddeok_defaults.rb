class AddDefaultFinishedProductsToGijeongddeokDefaults < ActiveRecord::Migration[8.1]
  def change
    add_column :gijeongddeok_defaults, :default_finished_product_ids, :json
  end
end
