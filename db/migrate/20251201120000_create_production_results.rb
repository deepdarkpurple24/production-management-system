class CreateProductionResults < ActiveRecord::Migration[8.0]
  def change
    # 생산 실적 (생산품관리)
    create_table :production_results do |t|
      t.references :production_plan, null: false, foreign_key: true
      t.references :packaging_unit, null: false, foreign_key: true
      t.integer :good_quantity, default: 0       # 완제품 수량 (박스)
      t.integer :defect_count, default: 0        # 불량 개수 (개별)
      t.text :notes                               # 비고
      t.boolean :packaging_processed, default: false  # 포장재 출고 처리 여부

      t.timestamps
    end

    add_index :production_results, [ :production_plan_id, :packaging_unit_id ], unique: true, name: 'idx_prod_results_plan_unit'
  end
end
