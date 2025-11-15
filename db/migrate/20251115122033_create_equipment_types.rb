class CreateEquipmentTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_types do |t|
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end
