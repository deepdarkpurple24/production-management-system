class ChangeIngredientEquipmentToReference < ActiveRecord::Migration[8.1]
  def change
    # equipment 컬럼을 equipment_id로 변경
    remove_column :ingredients, :equipment, :string
    add_column :ingredients, :equipment_id, :integer

    # cooking_method 컬럼을 equipment_mode_id로 변경
    remove_column :ingredients, :cooking_method, :text
    add_column :ingredients, :equipment_mode_id, :integer
  end
end
