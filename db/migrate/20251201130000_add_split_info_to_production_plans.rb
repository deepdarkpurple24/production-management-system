class AddSplitInfoToProductionPlans < ActiveRecord::Migration[8.0]
  def change
    # 기정떡 분할 정보
    add_column :production_plans, :is_gijeongddeok, :boolean, default: false
    add_column :production_plans, :split_count, :integer, default: 1  # 분할 횟수 (1통을 몇 번 나눠서 반죽할지)
    add_column :production_plans, :split_unit, :decimal, precision: 3, scale: 1, default: 1.0  # 분할 단위 (0.5, 1.0 등)
  end
end
