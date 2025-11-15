class ChangeEquipmentTypeToReference < ActiveRecord::Migration[8.1]
  def change
    # equipment_type 컬럼을 equipment_type_id로 변경
    remove_column :equipment, :equipment_type, :string
    add_column :equipment, :equipment_type_id, :integer
  end
end
