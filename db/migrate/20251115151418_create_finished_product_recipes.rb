class CreateFinishedProductRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :finished_product_recipes do |t|
      t.references :finished_product, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.decimal :quantity
      t.integer :position
      t.text :notes

      t.timestamps
    end
  end
end
