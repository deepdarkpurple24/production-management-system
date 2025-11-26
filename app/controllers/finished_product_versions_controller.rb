class FinishedProductVersionsController < ApplicationController
  before_action :set_finished_product
  before_action :set_version, only: [ :destroy ]

  def index
    @versions = @finished_product.finished_product_versions.order(version_number: :desc)
  end

  def destroy
    @version.destroy
    redirect_to finished_product_finished_product_versions_path(@finished_product), notice: "수정내역이 삭제되었습니다."
  end

  private

  def set_finished_product
    @finished_product = FinishedProduct.find(params[:finished_product_id])
  end

  def set_version
    @version = @finished_product.finished_product_versions.find(params[:id])
  end
end
