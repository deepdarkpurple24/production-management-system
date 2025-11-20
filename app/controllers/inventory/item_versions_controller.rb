class Inventory::ItemVersionsController < ApplicationController
  before_action :set_item
  before_action :set_version, only: [:destroy]

  def index
    @versions = @item.item_versions.order(version_number: :desc)
  end

  def destroy
    @version.destroy
    redirect_to inventory_item_item_versions_path(@item), notice: '수정내역이 삭제되었습니다.'
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end

  def set_version
    @version = @item.item_versions.find(params[:id])
  end
end
