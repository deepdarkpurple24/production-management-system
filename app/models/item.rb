class Item < ApplicationRecord
  # 연관관계
  has_many :receipts, dependent: :restrict_with_error
  has_many :shipments, dependent: :restrict_with_error
  has_many :item_versions, -> { order(version_number: :desc) }, dependent: :destroy
  has_many :opened_items, dependent: :destroy

  # 공급업체 배열 직렬화
  serialize :suppliers, coder: JSON, type: Array

  # 유효성 검증
  validates :name, presence: true
  validates :item_code, presence: true, uniqueness: true
  validates :minimum_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :optimal_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :shelf_life_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # 품목코드 자동 생성
  before_validation :generate_item_code, on: :create
  before_update :create_version_snapshot

  # 재고 계산 메서드
  def total_receipts
    receipts.sum(:quantity)
  end

  def total_shipments
    shipments.sum(:quantity)
  end

  def current_stock
    total_receipts - total_shipments
  end

  def current_stock_weight
    return nil unless weight.present?
    current_stock * weight
  end

  def stock_status
    stock = current_stock

    if minimum_stock.present? && stock < minimum_stock
      :critical  # 최소재고량 미만
    elsif optimal_stock.present? && stock < optimal_stock
      :low  # 적정재고량 미만
    else
      :sufficient  # 충분
    end
  end

  def stock_status_color
    case stock_status
    when :critical
      "danger"
    when :low
      "warning"
    else
      "success"
    end
  end

  def stock_status_text
    case stock_status
    when :critical
      "부족"
    when :low
      "주의"
    else
      "충분"
    end
  end

  private

  def generate_item_code
    return if item_code.present?

    # 마지막 품목의 코드 번호를 가져와서 +1
    last_item = Item.order(:item_code).last
    if last_item && last_item.item_code =~ /ITEM-(\d+)/
      next_number = $1.to_i + 1
    else
      next_number = 1
    end

    self.item_code = "ITEM-#{next_number.to_s.rjust(4, '0')}"
  end

  def create_version_snapshot
    # 변경사항이 있는지 체크
    return unless changed?

    version_num = item_versions.maximum(:version_number).to_i + 1
    change_list = []

    # 기본 정보 변경 감지
    if name_changed?
      change_list << "품목명: '#{name_was}' → '#{name}'"
    end

    if item_code_changed?
      change_list << "품목코드: '#{item_code_was}' → '#{item_code}'"
    end

    if category_changed?
      change_list << "카테고리: '#{category_was}' → '#{category}'"
    end

    if storage_location_changed?
      change_list << "보관 위치: '#{storage_location_was}' → '#{storage_location}'"
    end

    if unit_changed?
      change_list << "재고 단위: '#{unit_was}' → '#{unit}'"
    end

    if minimum_stock_changed?
      change_list << "최소재고량: '#{minimum_stock_was}' → '#{minimum_stock}'"
    end

    if optimal_stock_changed?
      change_list << "적정재고량: '#{optimal_stock_was}' → '#{optimal_stock}'"
    end

    if weight_changed?
      change_list << "중량: '#{weight_was}' → '#{weight}'"
    end

    if weight_unit_changed?
      change_list << "중량 단위: '#{weight_unit_was}' → '#{weight_unit}'"
    end

    if barcode_changed?
      change_list << "바코드: '#{barcode_was}' → '#{barcode}'"
    end

    if suppliers_changed?
      change_list << "공급업체 변경"
    end

    if notes_changed?
      change_list << "비고 변경"
    end

    # 변경사항이 없으면 기본 메시지
    change_list << "품목 수정" if change_list.empty?

    # 이전 데이터 스냅샷 저장 (변경 전 데이터 저장)
    item_versions.create!(
      version_number: version_num,
      name: name_was || name,
      item_code: item_code_was || item_code,
      category: category_was || category,
      storage_location: storage_location_was || storage_location,
      stock_unit: unit_was || unit,
      minimum_stock: minimum_stock_was || minimum_stock,
      optimal_stock: optimal_stock_was || optimal_stock,
      weight: weight_was || weight,
      barcode: barcode_was || barcode,
      notes: notes_was || notes,
      changed_by: "System",
      changed_at: Time.current,
      change_summary: change_list.join(", "),
      item_data: {
        suppliers: suppliers_was || suppliers,
        weight_unit: weight_unit_was || weight_unit
      }
    )
  end
end
