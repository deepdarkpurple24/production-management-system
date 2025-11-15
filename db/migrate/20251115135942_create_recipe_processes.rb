class CreateRecipeProcesses < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_processes do |t|
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end
