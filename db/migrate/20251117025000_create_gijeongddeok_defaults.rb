class CreateGijeongddeokDefaults < ActiveRecord::Migration[8.1]
  def change
    create_table :gijeongddeok_defaults do |t|
      # 온도 관리
      t.decimal :fermentation_room_temp, precision: 10, scale: 1
      t.decimal :refrigeration_room_temp, precision: 10, scale: 1
      t.decimal :water_temp, precision: 10, scale: 1
      t.decimal :flour_temp, precision: 10, scale: 1
      t.decimal :porridge_temp, precision: 10, scale: 1
      t.decimal :dough_temp, precision: 10, scale: 1

      # 재료 투입량
      t.integer :yeast_amount
      t.decimal :steiva_amount, precision: 10, scale: 1
      t.integer :salt_amount
      t.integer :sugar_amount
      t.decimal :water_amount, precision: 10, scale: 1
      t.decimal :dough_count, precision: 10, scale: 1

      # 막걸리
      t.decimal :makgeolli_consumption, precision: 10, scale: 1

      t.timestamps
    end
  end
end
