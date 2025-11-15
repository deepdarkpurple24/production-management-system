class CreateEquipmentModes < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_modes do |t|
      t.references :equipment_type, null: false, foreign_key: true
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end
