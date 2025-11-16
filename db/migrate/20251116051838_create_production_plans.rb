class CreateProductionPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :production_plans do |t|
      t.references :finished_product, null: false, foreign_key: true
      t.date :production_date
      t.integer :quantity
      t.text :notes

      t.timestamps
    end
  end
end
