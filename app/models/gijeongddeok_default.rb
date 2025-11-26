# 기정떡 기본값 - 생산일지 초기값
class GijeongddeokDefault < ApplicationRecord
  # 단일 레코드만 존재하도록 보장
  def self.instance
    first_or_create!
  end

  # 기본 필드 목록 (개별 컬럼으로 존재)
  STANDARD_FIELDS = %w[
    fermentation_room_temp refrigeration_room_temp
    water_temp flour_temp porridge_temp dough_temp
    yeast_amount steiva_amount salt_amount sugar_amount
    water_amount dough_count makgeolli_consumption
  ].freeze

  # 커스텀 필드인지 확인
  def custom_field?(field_name)
    !STANDARD_FIELDS.include?(field_name.to_s)
  end

  # 필드 값 읽기 (커스텀 필드는 JSON에서, 기본 필드는 컬럼에서)
  def read_field(field_name)
    if custom_field?(field_name)
      (custom_field_defaults || {})[field_name.to_s]
    else
      read_attribute(field_name)
    end
  end

  # 필드 값 쓰기 (커스텀 필드는 JSON에, 기본 필드는 컬럼에)
  def write_field(field_name, value)
    if custom_field?(field_name)
      self.custom_field_defaults ||= {}
      self.custom_field_defaults[field_name.to_s] = value
    else
      write_attribute(field_name, value)
    end
  end
end
