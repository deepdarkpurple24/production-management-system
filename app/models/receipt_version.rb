class ReceiptVersion < ApplicationRecord
  belongs_to :receipt

  validates :version_number, presence: true
  validates :changed_at, presence: true

  def item_name
    receipt_data&.dig("item_name")
  end
end
