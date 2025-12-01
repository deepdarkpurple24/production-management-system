class AddHalfBatchIngredientsToGijeongddeokDefaults < ActiveRecord::Migration[8.0]
  def change
    # 0.5통일 때 추가 재료 설정 (JSON 형태로 저장)
    add_column :gijeongddeok_defaults, :half_batch_extra_ingredients, :json, default: []
  end
end
