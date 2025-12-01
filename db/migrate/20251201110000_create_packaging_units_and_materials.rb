class CreatePackagingUnitsAndMaterials < ActiveRecord::Migration[8.0]
  def change
    # 포장 단위 (예: 30개입, 16개입)
    create_table :packaging_units do |t|
      t.references :finished_product, null: false, foreign_key: true
      t.string :name, null: false           # 포장 단위명 (예: "30개입", "16개입")
      t.integer :pieces_per_unit, null: false  # 단위당 개수 (예: 30, 16)
      t.integer :position, default: 0
      t.text :notes

      t.timestamps
    end

    # 포장 단위별 사용 포장재
    create_table :packaging_unit_materials do |t|
      t.references :packaging_unit, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true  # 포장재 품목
      t.string :material_type                              # 내포장재, 외포장재 등
      t.decimal :quantity_per_unit, precision: 10, scale: 2, default: 1  # 단위당 사용량
      t.integer :position, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
