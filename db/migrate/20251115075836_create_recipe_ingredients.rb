class CreateRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true  # 소계 행일 때는 null
      t.decimal :weight, precision: 10, scale: 2
      t.boolean :is_main, default: false
      t.integer :position, default: 0
      t.string :row_type, default: 'ingredient'  # 'ingredient' 또는 'subtotal'
      t.text :notes

      t.timestamps
    end

    add_index :recipe_ingredients, :position
  end
end
