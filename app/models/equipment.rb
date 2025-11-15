class Equipment < ApplicationRecord
  belongs_to :equipment_type, optional: true
  has_many :recipe_equipments, dependent: :destroy
  has_many :recipes, through: :recipe_equipments

  validates :name, presence: true
  validates :status, inclusion: { in: %w[정상 점검중 고장 폐기] }, allow_blank: true
end
