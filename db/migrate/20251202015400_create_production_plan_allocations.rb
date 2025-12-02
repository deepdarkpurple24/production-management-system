class CreateProductionPlanAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :production_plan_allocations do |t|
      t.references :production_plan, null: false, foreign_key: true
      t.references :finished_product, null: false, foreign_key: true
      t.integer :quantity, default: 0

      t.timestamps
    end

    # 같은 생산계획에 같은 완제품 중복 방지
    add_index :production_plan_allocations, [:production_plan_id, :finished_product_id], unique: true, name: 'idx_plan_allocations_unique'
  end
end
