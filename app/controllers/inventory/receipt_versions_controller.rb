class Inventory::ReceiptVersionsController < ApplicationController
  before_action :set_receipt
  before_action :set_version, only: [ :destroy ]

  def index
    @versions = @receipt.receipt_versions.order(version_number: :desc)
  end

  def destroy
    @version.destroy
    redirect_to inventory_receipt_receipt_versions_path(@receipt), notice: "수정내역이 삭제되었습니다."
  end

  private

  def set_receipt
    @receipt = Receipt.find(params[:receipt_id])
  end

  def set_version
    @version = @receipt.receipt_versions.find(params[:id])
  end
end
