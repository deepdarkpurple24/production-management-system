class ShipmentVersion < ApplicationRecord
  belongs_to :shipment

  validates :version_number, presence: true
  validates :changed_at, presence: true

  def item_name
    shipment_data&.dig("item_name")
  end
end
