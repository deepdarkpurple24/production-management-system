# frozen_string_literal: true

class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # 기본값 정의
  DEFAULTS = {
    "session_timeout_minutes" => "2",
    "session_warning_seconds" => "30"
  }.freeze

  DESCRIPTIONS = {
    "session_timeout_minutes" => "세션 타임아웃 시간 (분)",
    "session_warning_seconds" => "로그아웃 경고 표시 시간 (초)"
  }.freeze

  # 설정값 가져오기 (없으면 기본값 반환)
  def self.get(key)
    setting = find_by(key: key)
    setting&.value || DEFAULTS[key.to_s]
  end

  # 설정값 저장하기
  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.description ||= DESCRIPTIONS[key.to_s]
    setting.save
  end

  # 세션 타임아웃 (분)
  def self.session_timeout_minutes
    get("session_timeout_minutes").to_i
  end

  # 세션 경고 시간 (초)
  def self.session_warning_seconds
    get("session_warning_seconds").to_i
  end

  # 세션 경고 시간 (분 단위, JavaScript용)
  def self.session_warning_minutes
    session_warning_seconds / 60.0
  end
end
