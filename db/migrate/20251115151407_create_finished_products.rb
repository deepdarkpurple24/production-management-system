class CreateFinishedProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :finished_products do |t|
      t.string :name
      t.decimal :weight
      t.string :weight_unit
      t.text :description
      t.text :notes

      t.timestamps
    end
  end
end
