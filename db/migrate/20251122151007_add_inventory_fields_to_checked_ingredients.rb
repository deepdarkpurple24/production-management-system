class AddInventoryFieldsToCheckedIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :checked_ingredients, :used_weight, :decimal, precision: 10, scale: 2
    add_column :checked_ingredients, :expiration_date, :date
    add_reference :checked_ingredients, :receipt, foreign_key: true
    add_reference :checked_ingredients, :opened_item, foreign_key: true
  end
end
