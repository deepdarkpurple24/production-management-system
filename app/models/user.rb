# 사용자 계정 및 인증 관리
# Devise 기반 인증, 디바이스별 접근 제어, 로그인 이력 추적
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :confirmable

  # Associations
  has_many :authorized_devices, dependent: :destroy
  has_many :login_histories, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :sub_admins, -> { where(sub_admin: true) }
  scope :regular_users, -> { where(admin: false, sub_admin: false) }

  # Methods
  def admin?
    admin
  end

  def sub_admin?
    sub_admin
  end

  def has_admin_privileges?
    admin? || sub_admin?
  end

  def device_authorized?(fingerprint)
    authorized_devices.exists?(fingerprint: fingerprint, active: true)
  end

  def authorize_device(fingerprint, device_info = {})
    authorized_devices.create!(
      fingerprint: fingerprint,
      device_name: device_info[:device_name],
      browser: device_info[:browser],
      os: device_info[:os],
      active: true
    )
  end

  def revoke_device(fingerprint)
    authorized_devices.where(fingerprint: fingerprint).update_all(active: false)
  end
end
