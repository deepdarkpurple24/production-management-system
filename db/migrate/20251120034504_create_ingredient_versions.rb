class CreateIngredientVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_versions do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.integer :version_number
      t.string :name
      t.text :description
      t.text :notes
      t.decimal :production_quantity
      t.string :production_unit
      t.integer :equipment_type_id
      t.integer :equipment_mode_id
      t.integer :cooking_time
      t.string :changed_by
      t.datetime :changed_at
      t.text :change_summary
      t.json :ingredient_data

      t.timestamps
    end

    add_index :ingredient_versions, [ :ingredient_id, :version_number ]
  end
end
