class CreateProductionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :production_logs do |t|
      t.references :production_plan, null: false, foreign_key: true
      t.references :finished_product, null: false, foreign_key: true
      t.date :production_date
      t.time :production_time
      t.text :notes

      # 기정떡 전용 필드
      t.decimal :dough_count, precision: 10, scale: 1
      t.decimal :fermentation_room_temp, precision: 10, scale: 1
      t.decimal :refrigeration_room_temp, precision: 10, scale: 1
      t.integer :yeast_amount
      t.decimal :steiva_amount, precision: 10, scale: 1
      t.integer :salt_amount
      t.integer :sugar_amount
      t.decimal :water_amount, precision: 10, scale: 1
      t.decimal :water_temp, precision: 10, scale: 1
      t.decimal :flour_temp, precision: 10, scale: 1
      t.decimal :porridge_temp, precision: 10, scale: 1
      t.decimal :dough_temp, precision: 10, scale: 1
      t.decimal :makgeolli_consumption, precision: 10, scale: 1
      t.date :makgeolli_expiry_date

      t.timestamps
    end
  end
end
