class Inventory::ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  def index
    @items = Item.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      respond_to do |format|
        format.html { redirect_to inventory_items_path, notice: '품목이 성공적으로 등록되었습니다.' }
        format.json { render json: { success: true, item: { id: @item.id, name: @item.name, suppliers: @item.suppliers } } }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @item.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to inventory_item_path(@item), notice: '품목이 성공적으로 수정되었습니다.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to inventory_items_path, notice: '품목이 성공적으로 삭제되었습니다.'
  end

  # 품목의 공급업체 목록 반환 (JSON)
  def suppliers
    @item = Item.find(params[:id])
    suppliers_array = @item.suppliers

    # suppliers가 배열이 아닌 경우 처리
    unless suppliers_array.is_a?(Array)
      suppliers_array = []
    end

    render json: {
      suppliers: suppliers_array,
      weight: @item.weight,
      weight_unit: @item.weight_unit
    }
  rescue ActiveRecord::RecordNotFound
    render json: { suppliers: [], error: 'Item not found' }, status: :not_found
  end

  # 품목에 새 공급업체 추가 (JSON)
  def add_supplier
    @item = Item.find(params[:id])
    new_supplier = params[:supplier]&.strip

    if new_supplier.blank?
      render json: { success: false, error: '공급업체 이름을 입력해주세요.' }, status: :unprocessable_entity
      return
    end

    # 기존 공급업체 배열 가져오기
    suppliers = @item.suppliers || []

    # 중복 확인
    if suppliers.include?(new_supplier)
      render json: { success: false, error: '이미 등록된 공급업체입니다.' }, status: :unprocessable_entity
      return
    end

    # 새 공급업체 추가
    suppliers << new_supplier
    @item.suppliers = suppliers

    if @item.save
      render json: { success: true, suppliers: @item.suppliers }
    else
      render json: { success: false, error: '공급업체 추가에 실패했습니다.' }, status: :unprocessable_entity
    end
  end

  # 바코드로 품목 검색 (JSON)
  def find_by_barcode
    barcode = params[:barcode]&.strip

    if barcode.blank?
      render json: { success: false, error: '바코드를 입력해주세요.' }, status: :unprocessable_entity
      return
    end

    @item = Item.find_by(barcode: barcode)

    if @item
      render json: {
        success: true,
        item: {
          id: @item.id,
          name: @item.name,
          weight: @item.weight,
          weight_unit: @item.weight_unit,
          suppliers: @item.suppliers || []
        }
      }
    else
      render json: { success: false, error: '바코드를 찾을 수 없습니다.' }, status: :not_found
    end
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :category, :weight, :weight_unit, :minimum_stock, :optimal_stock, :storage_location, :barcode, :shelf_life_days, :notes, suppliers: [])
  end
end
