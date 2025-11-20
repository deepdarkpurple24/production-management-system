class Inventory::ShipmentsController < ApplicationController
  before_action :set_shipment, only: [:show, :edit, :update, :destroy]

  def index
    @shipments = Shipment.includes(:item).order(shipment_date: :desc)
  end

  def show
  end

  def new
    @shipment = Shipment.new(shipment_date: Time.current)
    @items = Item.all.order(:name)
    @shipment_purposes = ShipmentPurpose.all
    @shipment_requesters = ShipmentRequester.all
  end

  def edit
    @items = Item.all.order(:name)
    @shipment_purposes = ShipmentPurpose.all
    @shipment_requesters = ShipmentRequester.all
  end

  def create
    @shipment = Shipment.new(shipment_params)

    if @shipment.save
      redirect_to inventory_shipments_path, notice: '출고가 성공적으로 등록되었습니다.'
    else
      @items = Item.all.order(:name)
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @shipment.update(shipment_params)
      redirect_to inventory_shipments_path, notice: '출고 정보가 수정되었습니다.'
    else
      @items = Item.all.order(:name)
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shipment.destroy
    redirect_to inventory_shipments_path, notice: '출고 기록이 삭제되었습니다.'
  end

  private

  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  def shipment_params
    params.require(:shipment).permit(:item_id, :shipment_date, :quantity, :purpose, :requester, :notes)
  end
end
