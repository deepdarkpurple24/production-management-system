# 사용자 활동 로그 모델
class ActivityLog < ApplicationRecord
  belongs_to :user

  validates :action, presence: true
  validates :target_type, presence: true
  validates :performed_at, presence: true

  # 액션 타입
  ACTIONS = {
    create: "생성",
    update: "수정",
    destroy: "삭제"
  }.freeze

  # 대상 타입 (한글 표시용)
  TARGET_TYPES = {
    "Receipt" => "입고",
    "Shipment" => "출고",
    "Item" => "품목",
    "Recipe" => "레시피",
    "Ingredient" => "재료",
    "Equipment" => "장비",
    "FinishedProduct" => "완제품",
    "ProductionPlan" => "생산계획",
    "ProductionLog" => "생산일지",
    "OpenedItem" => "개봉품",
    "User" => "사용자"
  }.freeze

  # 활동 로그 기록
  def self.log(user:, action:, target:, request: nil, details: nil)
    return unless user

    create!(
      user: user,
      action: action.to_s,
      target_type: target.class.name,
      target_id: target.id,
      target_name: target_display_name(target),
      details: details&.to_json,
      ip_address: request&.remote_ip,
      browser: extract_browser(request),
      performed_at: Time.current
    )
  rescue => e
    Rails.logger.error "ActivityLog 기록 실패: #{e.message}"
  end

  # 대상 표시명 추출
  def self.target_display_name(target)
    if target.respond_to?(:name) && target.name.present?
      target.name
    elsif target.respond_to?(:item) && target.item&.name.present?
      target.item.name
    elsif target.is_a?(Receipt)
      "#{target.item&.name} 입고 (#{target.receipt_date})"
    elsif target.is_a?(Shipment)
      "#{target.item&.name} 출고 (#{target.shipment_date&.to_date})"
    else
      "##{target.id}"
    end
  end

  # 브라우저 정보 추출
  def self.extract_browser(request)
    return nil unless request
    user_agent = request.user_agent || ""
    case user_agent
    when /Chrome/i then "Chrome"
    when /Safari/i then "Safari"
    when /Firefox/i then "Firefox"
    when /Edge/i then "Edge"
    else "기타"
    end
  end

  # 액션 한글 표시
  def action_name
    ACTIONS[action.to_sym] || action
  end

  # 대상 타입 한글 표시
  def target_type_name
    TARGET_TYPES[target_type] || target_type
  end

  # 상세 내용 파싱
  def parsed_details
    return {} if details.blank?
    JSON.parse(details)
  rescue
    {}
  end

  # 요약 메시지
  def summary
    "#{target_type_name} #{action_name}: #{target_name}"
  end
end
