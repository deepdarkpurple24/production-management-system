class Receipt < ApplicationRecord
  belongs_to :item
  has_many :receipt_versions, -> { order(version_number: :desc) }, dependent: :destroy
  has_many :opened_items, dependent: :destroy
  has_many :checked_ingredients, dependent: :nullify

  validates :receipt_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_expiration_date
  before_update :create_version_snapshot

  private

  def calculate_expiration_date
    # 제조일이 입력되고, 품목에 shelf_life_days가 설정되어 있으면 유통기한 자동 계산
    if manufacturing_date.present? && item&.shelf_life_days.present?
      self.expiration_date = manufacturing_date + item.shelf_life_days.days
    end
  end

  def create_version_snapshot
    return unless changed?

    version_num = receipt_versions.maximum(:version_number).to_i + 1
    change_list = []

    # 기본 정보 변경 감지
    if item_id_changed?
      change_list << "품목 변경"
    end

    if receipt_date_changed?
      change_list << "입고일: '#{receipt_date_was}' → '#{receipt_date}'"
    end

    if quantity_changed?
      change_list << "수량: '#{quantity_was}' → '#{quantity}'"
    end

    if unit_price_changed?
      change_list << "단가: '#{unit_price_was}' → '#{unit_price}'"
    end

    if unit_weight_changed?
      change_list << "개당 중량: '#{unit_weight_was}' → '#{unit_weight}'"
    end

    if unit_weight_unit_changed?
      change_list << "중량 단위: '#{unit_weight_unit_was}' → '#{unit_weight_unit}'"
    end

    if manufacturing_date_changed?
      change_list << "제조일: '#{manufacturing_date_was}' → '#{manufacturing_date}'"
    end

    if expiration_date_changed?
      change_list << "유통기한: '#{expiration_date_was}' → '#{expiration_date}'"
    end

    if supplier_changed?
      change_list << "공급업체: '#{supplier_was}' → '#{supplier}'"
    end

    if notes_changed?
      change_list << "비고 변경"
    end

    # 변경사항이 없으면 기본 메시지
    change_list << "입고 정보 수정" if change_list.empty?

    # 이전 데이터 스냅샷 저장 (변경 전 데이터 저장)
    receipt_versions.create!(
      version_number: version_num,
      item_id: item_id_was || item_id,
      receipt_date: receipt_date_was || receipt_date,
      quantity: quantity_was || quantity,
      unit_price: unit_price_was || unit_price,
      unit_weight: unit_weight_was || unit_weight,
      unit_weight_unit: unit_weight_unit_was || unit_weight_unit,
      manufacturing_date: manufacturing_date_was || manufacturing_date,
      expiration_date: expiration_date_was || expiration_date,
      supplier: supplier_was || supplier,
      notes: notes_was || notes,
      changed_by: "System",
      changed_at: Time.current,
      change_summary: change_list.join(", "),
      receipt_data: {
        item_name: item&.name
      }
    )
  end
end
