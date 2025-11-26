# 재료 구성 정보 - 품목 조합 및 생산 단위
class Ingredient < ApplicationRecord
  belongs_to :equipment_type, optional: true
  belongs_to :equipment_mode, optional: true
  has_many :ingredient_items, -> { order(position: :asc) }, dependent: :destroy
  has_many :items, through: :ingredient_items
  has_many :ingredient_versions, -> { order(version_number: :desc) }, dependent: :destroy

  accepts_nested_attributes_for :ingredient_items, allow_destroy: true

  validates :name, presence: true

  before_update :create_version_snapshot

  # 총 수량 계산 (소계 제외)
  def total_quantity
    ingredient_items.where(row_type: "item").sum(:quantity)
  end

  # 소계 전 수량 계산
  def subtotal_quantity
    subtotal_item = ingredient_items.find_by(row_type: "subtotal")
    if subtotal_item
      ingredient_items.where(row_type: "item")
                      .where("position < ?", subtotal_item.position)
                      .sum(:quantity)
    else
      total_quantity
    end
  end

  private

  def create_version_snapshot
    # 변경사항이 있는지 체크
    has_changes = changed? ||
                  ingredient_items.any? { |ii| ii.changed? || ii.marked_for_destruction? || ii.new_record? }

    return unless has_changes

    # 데이터베이스에서 현재 저장된 값 조회 (변경 전 값)
    current_ingredient = Ingredient.includes(:ingredient_items).find(id)

    version_num = ingredient_versions.maximum(:version_number).to_i + 1
    change_list = []

    # 기본 정보 변경 감지
    if name_changed?
      change_list << "재료명: '#{name_was}' → '#{name}'"
    end

    if description_changed?
      change_list << "설명 변경"
    end

    if notes_changed?
      change_list << "비고 변경"
    end

    if production_quantity_changed?
      change_list << "생산 수량: '#{production_quantity_was}' → '#{production_quantity}'"
    end

    if production_unit_changed?
      change_list << "생산 단위: '#{production_unit_was}' → '#{production_unit}'"
    end

    if equipment_type_id_changed?
      change_list << "장비 구분 변경"
    end

    if equipment_mode_id_changed?
      change_list << "장비 모드 변경"
    end

    if cooking_time_changed?
      change_list << "조리 시간: '#{cooking_time_was}' → '#{cooking_time}'"
    end

    # 재료 항목 변경 감지
    if ingredient_items.any? { |ii| ii.changed? || ii.marked_for_destruction? || ii.new_record? }
      change_list << "재료 구성 변경"
    end

    # 변경사항이 없으면 기본 메시지
    change_list << "재료 수정" if change_list.empty?

    # 이전 데이터 스냅샷 저장 (데이터베이스의 현재 값 = 변경 전 값)
    ingredient_versions.create!(
      version_number: version_num,
      name: current_ingredient.name,
      description: current_ingredient.description,
      notes: current_ingredient.notes,
      production_quantity: current_ingredient.production_quantity,
      production_unit: current_ingredient.production_unit,
      equipment_type_id: current_ingredient.equipment_type_id,
      equipment_mode_id: current_ingredient.equipment_mode_id,
      cooking_time: current_ingredient.cooking_time,
      changed_by: "System",
      changed_at: Time.current,
      change_summary: change_list.join(", "),
      ingredient_data: {
        ingredient_items: current_ingredient.ingredient_items.map { |ii|
          {
            item_id: ii.item_id,
            item_name: ii.item&.name,
            referenced_ingredient_id: ii.referenced_ingredient_id,
            referenced_ingredient_name: ii.referenced_ingredient&.name,
            quantity: ii.quantity,
            unit: ii.unit,
            custom_name: ii.custom_name,
            notes: ii.notes,
            row_type: ii.row_type,
            source_type: ii.source_type,
            position: ii.position
          }
        }
      }
    )
  end
end
