class AddBatchIndexToCheckedIngredients < ActiveRecord::Migration[8.1]
  def change
    # batch_index 컬럼 추가 (기본값 0)
    add_column :checked_ingredients, :batch_index, :integer, default: 0, null: false

    # 기존 unique index 제거
    remove_index :checked_ingredients, name: 'index_checked_ingredients_uniqueness'

    # batch_index를 포함한 새로운 unique index 추가
    add_index :checked_ingredients,
              [:production_log_id, :recipe_id, :ingredient_index, :batch_index],
              unique: true,
              name: 'index_checked_ingredients_uniqueness'
  end
end
