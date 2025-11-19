class AddUnitToGijeongddeokFieldOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :gijeongddeok_field_orders, :unit, :string
  end
end
