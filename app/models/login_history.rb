class LoginHistory < ApplicationRecord
  belongs_to :user, optional: true  # Allow failed login attempts without user

  # Validations
  validates :attempted_at, presence: true
  validates :success, inclusion: { in: [true, false] }

  # Scopes
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :recent, -> { order(attempted_at: :desc) }
  scope :today, -> { where('attempted_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('attempted_at >= ?', Time.current.beginning_of_week) }
  scope :by_ip, ->(ip) { where(ip_address: ip) }

  # Class methods
  def self.log_attempt(user:, fingerprint:, ip:, browser:, os:, device_name:, success:, reason: nil)
    create!(
      user: user,
      fingerprint: fingerprint,
      ip_address: ip,
      browser: browser,
      os: os,
      device_name: device_name,
      success: success,
      failure_reason: reason,
      attempted_at: Time.current
    )
  end

  # Instance methods
  def display_status
    success ? '성공' : '실패'
  end

  def status_color
    success ? 'success' : 'danger'
  end
end
