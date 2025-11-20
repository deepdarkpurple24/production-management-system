class CreateFinishedProductVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :finished_product_versions do |t|
      t.references :finished_product, null: false, foreign_key: true
      t.integer :version_number
      t.string :name
      t.text :description
      t.text :notes
      t.decimal :weight
      t.string :weight_unit
      t.string :changed_by
      t.datetime :changed_at
      t.text :change_summary
      t.json :finished_product_data

      t.timestamps
    end

    add_index :finished_product_versions, [:finished_product_id, :version_number]
  end
end
