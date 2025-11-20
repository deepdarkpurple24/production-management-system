class FinishedProduct < ApplicationRecord
  has_many :finished_product_recipes, -> { order(position: :asc) }, dependent: :destroy
  has_many :recipes, through: :finished_product_recipes
  has_many :production_plans, dependent: :destroy
  has_many :production_logs, dependent: :destroy
  has_many :finished_product_versions, -> { order(version_number: :desc) }, dependent: :destroy

  accepts_nested_attributes_for :finished_product_recipes, allow_destroy: true

  validates :name, presence: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true

  before_update :create_version_snapshot

  private

  def create_version_snapshot
    # 변경사항이 있는지 체크
    has_changes = changed? ||
                  finished_product_recipes.any? { |fpr| fpr.changed? || fpr.marked_for_destruction? || fpr.new_record? }

    return unless has_changes

    # 데이터베이스에서 현재 저장된 값 조회 (변경 전 값)
    current_product = FinishedProduct.includes(:finished_product_recipes).find(id)

    version_num = finished_product_versions.maximum(:version_number).to_i + 1
    change_list = []

    # 기본 정보 변경 감지
    if name_changed?
      change_list << "완제품명: '#{name_was}' → '#{name}'"
    end

    if description_changed?
      change_list << "설명 변경"
    end

    if notes_changed?
      change_list << "비고 변경"
    end

    if weight_changed?
      change_list << "중량: '#{weight_was}' → '#{weight}'"
    end

    if weight_unit_changed?
      change_list << "중량 단위: '#{weight_unit_was}' → '#{weight_unit}'"
    end

    # 레시피 구성 변경 감지
    if finished_product_recipes.any? { |fpr| fpr.changed? || fpr.marked_for_destruction? || fpr.new_record? }
      change_list << "레시피 구성 변경"
    end

    # 변경사항이 없으면 기본 메시지
    change_list << "완제품 수정" if change_list.empty?

    # 이전 데이터 스냅샷 저장 (데이터베이스의 현재 값 = 변경 전 값)
    finished_product_versions.create!(
      version_number: version_num,
      name: name_was || name,
      description: description_was || description,
      notes: notes_was || notes,
      weight: weight_was || weight,
      weight_unit: weight_unit_was || weight_unit,
      changed_by: "System",
      changed_at: Time.current,
      change_summary: change_list.join(", "),
      finished_product_data: {
        finished_product_recipes: current_product.finished_product_recipes.map { |fpr|
          {
            recipe_id: fpr.recipe_id,
            recipe_name: fpr.recipe&.name,
            quantity: fpr.quantity,
            notes: fpr.notes,
            position: fpr.position
          }
        }
      }
    )
  end
end
