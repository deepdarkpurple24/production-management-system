class CreateCheckedIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :checked_ingredients do |t|
      t.references :production_log, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.integer :ingredient_index, null: false

      t.timestamps
    end

    # 같은 production_log + recipe + ingredient_index 조합은 한 번만 저장
    add_index :checked_ingredients,
              [ :production_log_id, :recipe_id, :ingredient_index ],
              unique: true,
              name: 'index_checked_ingredients_uniqueness'
  end
end
