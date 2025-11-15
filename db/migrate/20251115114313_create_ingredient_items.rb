class CreateIngredientItems < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_items do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2
      t.text :notes
      t.integer :position, default: 0
      t.string :row_type, default: 'item'

      t.timestamps
    end

    add_index :ingredient_items, :position
  end
end
