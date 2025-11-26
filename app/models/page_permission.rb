# 페이지 권한 - 사용자 역할별 접근 제어
class PagePermission < ApplicationRecord
  validates :page_key, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, -> { order(position: :asc) }
  scope :allowed_for_users, -> { where(allowed_for_users: true) }

  # 기본 페이지 목록 정의
  DEFAULT_PAGES = [
    { page_key: "home", name: "대시보드", description: "메인 대시보드 페이지" },
    { page_key: "inventory", name: "재고관리", description: "재고 관리 메뉴 전체" },
    { page_key: "inventory_items", name: "재고관리 > 품목관리", description: "품목 목록 및 관리" },
    { page_key: "inventory_receipts", name: "재고관리 > 입고", description: "입고 내역 관리" },
    { page_key: "inventory_shipments", name: "재고관리 > 출고", description: "출고 내역 관리" },
    { page_key: "inventory_stocks", name: "재고관리 > 재고현황", description: "현재 재고 현황 조회" },
    { page_key: "inventory_opened_items", name: "재고관리 > 개봉품", description: "개봉품 관리" },
    { page_key: "recipes", name: "레시피관리", description: "레시피 목록 및 관리" },
    { page_key: "ingredients", name: "재료관리", description: "재료 목록 및 관리" },
    { page_key: "finished_products", name: "완제품관리", description: "완제품 목록 및 관리" },
    { page_key: "production", name: "생산관리", description: "생산 관리 메뉴 전체" },
    { page_key: "production_plans", name: "생산관리 > 생산계획", description: "생산 계획 관리" },
    { page_key: "production_logs", name: "생산관리 > 반죽일지", description: "반죽일지 관리" },
    { page_key: "equipments", name: "장비관리", description: "장비 목록 및 관리" },
    { page_key: "settings", name: "설정", description: "시스템 설정" }
  ].freeze

  # 기본 페이지 초기화
  def self.initialize_defaults!
    DEFAULT_PAGES.each_with_index do |page, index|
      find_or_create_by!(page_key: page[:page_key]) do |p|
        p.name = page[:name]
        p.description = page[:description]
        p.allowed_for_users = true
        p.position = index + 1
      end
    end
  end

  # 페이지 접근 권한 확인
  def self.allowed?(page_key, user)
    # 관리자는 모든 페이지 접근 가능
    return true if user&.admin?

    permission = find_by(page_key: page_key)
    return true if permission.nil? # 등록되지 않은 페이지는 기본 허용

    # 관리자 권한 확인
    return true if user&.sub_admin? && permission.allowed_for_sub_admins?

    # 일반 사용자 권한 확인
    permission.allowed_for_users?
  end

  # 메뉴 표시 여부 확인 (네비게이션용)
  def self.visible_for_user?(page_key, user)
    allowed?(page_key, user)
  end
end
