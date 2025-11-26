class AuthorizedDevice < ApplicationRecord
  belongs_to :user

  # Validations
  validates :fingerprint, presence: true
  validates :active, inclusion: { in: [ true, false ] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { order(last_used_at: :desc) }
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }

  # Callbacks
  before_create :set_last_used_at

  # Methods
  def update_last_used!
    update!(last_used_at: Time.current)
  end

  def deactivate!
    update!(active: false)
  end

  def display_name
    device_name.presence || "#{browser} on #{os}"
  end

  def generate_authorization_token!
    self.authorization_token = SecureRandom.urlsafe_base64(32)
    self.authorization_token_sent_at = Time.current
    save!
  end

  def authorization_token_valid?
    return false if authorization_token.blank?
    return false if authorization_token_sent_at.blank?

    # Token valid for 24 hours
    authorization_token_sent_at > 24.hours.ago
  end

  def approve!
    update!(status: "approved", active: true, authorization_token: nil, authorization_token_sent_at: nil)
  end

  def reject!
    update!(status: "rejected", active: false)
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  private

  def set_last_used_at
    self.last_used_at ||= Time.current
  end
end
