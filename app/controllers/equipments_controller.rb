class EquipmentsController < ApplicationController
  before_action :set_equipment, only: [ :show, :edit, :update, :destroy ]

  def index
    @equipments = Equipment.order(created_at: :desc)
  end

  def show
  end

  def new
    @equipment = Equipment.new
  end

  def create
    @equipment = Equipment.new(equipment_params)
    if @equipment.save
      log_activity(:create, @equipment)
      redirect_to equipments_path, notice: "장비가 성공적으로 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @equipment.update(equipment_params)
      log_activity(:update, @equipment)
      redirect_to equipments_path, notice: "장비가 성공적으로 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    log_activity(:destroy, @equipment)
    @equipment.destroy
    redirect_to equipments_path, notice: "장비가 성공적으로 삭제되었습니다."
  end

  private

  def set_equipment
    @equipment = Equipment.find(params[:id])
  end

  def equipment_params
    params.require(:equipment).permit(:name, :equipment_type_id, :manufacturer, :model_number, :purchase_date, :status, :location, :capacity, :capacity_unit, :notes)
  end
end
