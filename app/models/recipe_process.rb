class RecipeProcess < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  before_create :set_position

  default_scope { order(position: :asc) }

  private

  def set_position
    self.position ||= (RecipeProcess.unscoped.maximum(:position) || 0) + 1
  end
end
