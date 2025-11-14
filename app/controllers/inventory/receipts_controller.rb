class Inventory::ReceiptsController < ApplicationController
  before_action :set_receipt, only: [:show, :edit, :update, :destroy]

  def index
    @receipts = Receipt.includes(:item).order(receipt_date: :desc)
  end

  def show
  end

  def new
    @receipt = Receipt.new
    @items = Item.all.order(:name)
  end

  def edit
    @items = Item.all.order(:name)
  end

  def create
    @receipt = Receipt.new(receipt_params)

    if @receipt.save
      redirect_to inventory_receipts_path, notice: '입고가 성공적으로 등록되었습니다.'
    else
      @items = Item.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @receipt.update(receipt_params)
      redirect_to inventory_receipt_path(@receipt), notice: '입고 정보가 수정되었습니다.'
    else
      @items = Item.all.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @receipt.destroy
    redirect_to inventory_receipts_path, notice: '입고 기록이 삭제되었습니다.'
  end

  private

  def set_receipt
    @receipt = Receipt.find(params[:id])
  end

  def receipt_params
    params.require(:receipt).permit(:item_id, :receipt_date, :quantity, :manufacturing_date, :expiration_date, :unit_price, :supplier, :notes)
  end
end
