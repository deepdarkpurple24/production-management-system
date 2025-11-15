class CreateEquipment < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment do |t|
      t.string :name
      t.string :equipment_type
      t.string :manufacturer
      t.string :model_number
      t.date :purchase_date
      t.string :status
      t.string :location
      t.text :notes

      t.timestamps
    end
  end
end
