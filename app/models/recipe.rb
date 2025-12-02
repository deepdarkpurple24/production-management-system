# 레시피 정보 - 재료 구성 및 장비 요구사항
class Recipe < ApplicationRecord
  has_many :recipe_ingredients, -> { order(position: :asc) }, dependent: :destroy
  has_many :items, through: :recipe_ingredients
  has_many :recipe_equipments, -> { order(position: :asc) }, dependent: :destroy
  has_many :equipments, through: :recipe_equipments
  has_many :recipe_versions, -> { order(version_number: :desc) }, dependent: :destroy
  has_many :finished_product_recipes, dependent: :destroy
  has_many :finished_products, through: :finished_product_recipes
  has_many :production_plans, dependent: :nullify

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true
  accepts_nested_attributes_for :recipe_equipments, allow_destroy: true

  validates :name, presence: true

  before_update :create_version_snapshot

  # 주재료 총 중량 계산
  def main_ingredient_weight
    recipe_ingredients.where(is_main: true, row_type: "ingredient").sum(:weight)
  end

  # 총 중량 계산 (소계 제외)
  def total_weight
    recipe_ingredients.where(row_type: "ingredient").sum(:weight)
  end

  # 소계 전 중량 계산
  def subtotal_weight
    subtotal_ingredient = recipe_ingredients.find_by(row_type: "subtotal")
    if subtotal_ingredient
      recipe_ingredients.where(row_type: "ingredient")
                       .where("position < ?", subtotal_ingredient.position)
                       .sum(:weight)
    else
      total_weight
    end
  end

  # 소계 후 중량 계산
  def after_subtotal_weight
    subtotal_ingredient = recipe_ingredients.find_by(row_type: "subtotal")
    if subtotal_ingredient
      recipe_ingredients.where(row_type: "ingredient")
                       .where("position > ?", subtotal_ingredient.position)
                       .sum(:weight)
    else
      0
    end
  end

  private

  def create_version_snapshot
    # 변경사항이 있는지 체크
    has_changes = changed? ||
                  recipe_ingredients.any? { |ri| ri.changed? || ri.marked_for_destruction? || ri.new_record? } ||
                  recipe_equipments.any? { |re| re.changed? || re.marked_for_destruction? || re.new_record? }

    return unless has_changes

    # 데이터베이스에서 현재 저장된 값 조회 (변경 전 값)
    current_recipe = Recipe.includes(:recipe_ingredients, :recipe_equipments).find(id)

    version_num = recipe_versions.maximum(:version_number).to_i + 1
    change_list = []

    # 기본 정보 변경 감지
    if name_changed?
      change_list << "레시피명: '#{name_was}' → '#{name}'"
    end

    if description_changed?
      change_list << "설명 변경"
    end

    if notes_changed?
      change_list << "비고 변경"
    end

    # 재료 변경 감지
    if recipe_ingredients.any? { |ri| ri.changed? || ri.marked_for_destruction? || ri.new_record? }
      change_list << "재료 구성 변경"
    end

    # 장비 변경 감지
    if recipe_equipments.any? { |re| re.changed? || re.marked_for_destruction? || re.new_record? }
      change_list << "장비 구성 변경"
    end

    # 변경사항이 없으면 기본 메시지
    change_list << "레시피 수정" if change_list.empty?

    # 이전 데이터 스냅샷 저장 (데이터베이스의 현재 값 = 변경 전 값)
    recipe_versions.create!(
      version_number: version_num,
      name: name_was || name,
      description: description_was || description,
      notes: notes_was || notes,
      total_weight: current_recipe.total_weight,
      changed_by: "System",
      changed_at: Time.current,
      change_summary: change_list.join(", "),
      recipe_data: {
        ingredients: current_recipe.recipe_ingredients.map { |ri|
          {
            source_type: ri.source_type,
            item_id: ri.item_id,
            item_name: ri.item&.name,
            referenced_ingredient_id: ri.referenced_ingredient_id,
            referenced_ingredient_name: ri.referenced_ingredient&.name,
            display_name: ri.display_name,
            weight: ri.weight,
            is_main: ri.is_main,
            row_type: ri.row_type,
            notes: ri.notes,
            position: ri.position
          }
        },
        equipments: current_recipe.recipe_equipments.map { |re|
          {
            equipment_id: re.equipment_id,
            equipment_name: re.equipment&.name,
            process_id: re.process_id,
            process_name: re.recipe_process&.name,
            work_capacity: re.work_capacity,
            work_capacity_unit: re.work_capacity_unit,
            row_type: re.row_type,
            position: re.position
          }
        }
      }
    )
  end
end
