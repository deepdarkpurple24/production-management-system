class RecipeEquipment < ApplicationRecord
  belongs_to :recipe
  belongs_to :equipment, optional: true
  belongs_to :recipe_process, optional: true

  validates :equipment_id, presence: true, if: -> { row_type == 'equipment' }
  validates :process_id, presence: true, if: -> { row_type == 'process' }
end
