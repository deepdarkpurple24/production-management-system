class CreateGijeongddeokFieldOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :gijeongddeok_field_orders do |t|
      t.string :field_name, null: false
      t.string :label, null: false
      t.string :category, null: false # temperature, ingredient, makgeolli
      t.integer :position, null: false
      t.timestamps
    end

    add_index :gijeongddeok_field_orders, :position
    add_index :gijeongddeok_field_orders, :field_name, unique: true
  end
end
