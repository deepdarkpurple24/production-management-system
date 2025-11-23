class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Associations
  has_many :authorized_devices, dependent: :destroy
  has_many :login_histories, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }

  # Methods
  def admin?
    admin
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
