class GijeongddeokFieldOrder < ApplicationRecord
  validates :field_name, presence: true, uniqueness: true
  validates :label, presence: true
  validates :category, presence: true
  validates :position, presence: true

  default_scope { order(:position) }

  # 초기 데이터 생성
  def self.seed_defaults
    return if GijeongddeokFieldOrder.any?

    fields = [
      # 온도 관리
      { field_name: "fermentation_room_temp", label: "발효실 온도", category: "temperature", position: 1 },
      { field_name: "refrigeration_room_temp", label: "냉장실 온도", category: "temperature", position: 2 },
      { field_name: "water_temp", label: "물 온도", category: "temperature", position: 3 },
      { field_name: "flour_temp", label: "가루 온도", category: "temperature", position: 4 },
      { field_name: "porridge_temp", label: "죽 온도", category: "temperature", position: 5 },
      { field_name: "dough_temp", label: "반죽 온도", category: "temperature", position: 6 },
      # 재료 투입량
      { field_name: "yeast_amount", label: "이스트", category: "ingredient", position: 7 },
      { field_name: "steiva_amount", label: "스테비아", category: "ingredient", position: 8 },
      { field_name: "salt_amount", label: "소금", category: "ingredient", position: 9 },
      { field_name: "sugar_amount", label: "설탕", category: "ingredient", position: 10 },
      { field_name: "water_amount", label: "물", category: "ingredient", position: 11 },
      # 막걸리 관리
      { field_name: "makgeolli_consumption", label: "막걸리 소비량", category: "makgeolli", position: 12 }
    ]

    fields.each { |field| GijeongddeokFieldOrder.create!(field) }
  end

  # 카테고리별 필드 목록
  def self.by_category(category)
    where(category: category).order(:position)
  end
end
