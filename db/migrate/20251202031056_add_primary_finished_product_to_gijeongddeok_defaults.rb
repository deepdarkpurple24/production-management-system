class AddPrimaryFinishedProductToGijeongddeokDefaults < ActiveRecord::Migration[8.1]
  def change
    add_column :gijeongddeok_defaults, :primary_finished_product_id, :integer
  end
end
