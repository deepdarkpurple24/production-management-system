class CreateRecipeVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_versions do |t|
      t.references :recipe, null: false, foreign_key: true
      t.integer :version_number
      t.string :name
      t.text :description
      t.text :notes
      t.decimal :total_weight
      t.string :changed_by
      t.datetime :changed_at
      t.text :change_summary
      t.json :recipe_data

      t.timestamps
    end

    add_index :recipe_versions, [ :recipe_id, :version_number ]
  end
end
