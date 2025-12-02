class AddRecipeToProductionPlans < ActiveRecord::Migration[8.1]
  def change
    # 레시피 기반 생산계획을 위한 컬럼 추가
    add_reference :production_plans, :recipe, null: true, foreign_key: true
    add_column :production_plans, :unit_type, :string, default: '개'  # '개' 또는 '통'

    # finished_product를 optional로 변경 (기존 데이터 호환)
    change_column_null :production_plans, :finished_product_id, true
  end
end
