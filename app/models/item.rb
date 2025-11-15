class Item < ApplicationRecord
  # 연관관계
  has_many :receipts, dependent: :restrict_with_error
  has_many :shipments, dependent: :restrict_with_error

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
      'danger'
    when :low
      'warning'
    else
      'success'
    end
  end

  def stock_status_text
    case stock_status
    when :critical
      '부족'
    when :low
      '주의'
    else
      '충분'
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
end
