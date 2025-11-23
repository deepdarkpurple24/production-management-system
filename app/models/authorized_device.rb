class AuthorizedDevice < ApplicationRecord
  belongs_to :user

  # Validations
  validates :fingerprint, presence: true
  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { order(last_used_at: :desc) }

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

  private

  def set_last_used_at
    self.last_used_at ||= Time.current
  end
end
