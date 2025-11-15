class CreateRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_equipments do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :equipment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
