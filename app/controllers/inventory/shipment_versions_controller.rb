class Inventory::ShipmentVersionsController < ApplicationController
  before_action :set_shipment
  before_action :set_version, only: [ :destroy ]

  def index
    @versions = @shipment.shipment_versions.order(version_number: :desc)
  end

  def destroy
    @version.destroy
    redirect_to inventory_shipment_shipment_versions_path(@shipment), notice: "수정내역이 삭제되었습니다."
  end

  private

  def set_shipment
    @shipment = Shipment.find(params[:shipment_id])
  end

  def set_version
    @version = @shipment.shipment_versions.find(params[:id])
  end
end
