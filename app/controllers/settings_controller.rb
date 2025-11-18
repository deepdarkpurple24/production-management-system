class SettingsController < ApplicationController
  def index
    # 메인 설정 페이지 (버튼만 표시)
  end

  def system
    @shipment_purposes = ShipmentPurpose.all
    @shipment_requesters = ShipmentRequester.all
    @equipment_types = EquipmentType.all
    @recipe_processes = RecipeProcess.all
    @shipment_purpose = ShipmentPurpose.new
    @shipment_requester = ShipmentRequester.new
    @equipment_type = EquipmentType.new
    @equipment_mode = EquipmentMode.new
    @recipe_process = RecipeProcess.new
    @gijeongddeok_default = GijeongddeokDefault.instance
    @gijeongddeok_fields = GijeongddeokFieldOrder.all
  end

  def create_purpose
    @shipment_purpose = ShipmentPurpose.new(shipment_purpose_params)

    if @shipment_purpose.save
      redirect_to settings_system_path, notice: '출고 목적이 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @shipment_requester = ShipmentRequester.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_purpose
    @shipment_purpose = ShipmentPurpose.find(params[:id])
    @shipment_purpose.destroy
    redirect_to settings_system_path, notice: '출고 목적이 삭제되었습니다.'
  end

  def create_requester
    @shipment_requester = ShipmentRequester.new(shipment_requester_params)

    if @shipment_requester.save
      redirect_to settings_system_path, notice: '출고 요청자가 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @shipment_purpose = ShipmentPurpose.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_requester
    @shipment_requester = ShipmentRequester.find(params[:id])
    @shipment_requester.destroy
    redirect_to settings_system_path, notice: '출고 요청자가 삭제되었습니다.'
  end

  def update_purpose_positions
    params[:positions].each_with_index do |id, index|
      ShipmentPurpose.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  def update_requester_positions
    params[:positions].each_with_index do |id, index|
      ShipmentRequester.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  def create_equipment_type
    @equipment_type = EquipmentType.new(equipment_type_params)

    if @equipment_type.save
      redirect_to settings_system_path, notice: '장비 구분이 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @equipment_types = EquipmentType.all
      @shipment_purpose = ShipmentPurpose.new
      @shipment_requester = ShipmentRequester.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_equipment_type
    @equipment_type = EquipmentType.find(params[:id])
    @equipment_type.destroy
    redirect_to settings_system_path, notice: '장비 구분이 삭제되었습니다.'
  end

  def update_equipment_type_positions
    params[:positions].each_with_index do |id, index|
      EquipmentType.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  def create_equipment_mode
    @equipment_mode = EquipmentMode.new(equipment_mode_params)

    if @equipment_mode.save
      redirect_to settings_system_path, notice: '장비 모드가 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @equipment_types = EquipmentType.all
      @shipment_purpose = ShipmentPurpose.new
      @shipment_requester = ShipmentRequester.new
      @equipment_type = EquipmentType.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_equipment_mode
    @equipment_mode = EquipmentMode.find(params[:id])
    @equipment_mode.destroy
    redirect_to settings_system_path, notice: '장비 모드가 삭제되었습니다.'
  end

  def update_equipment_mode_positions
    params[:positions].each_with_index do |id, index|
      EquipmentMode.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  def get_equipment_modes
    equipment_type_id = params[:equipment_type_id]
    @equipment_modes = EquipmentMode.where(equipment_type_id: equipment_type_id)
    render json: @equipment_modes
  end

  def create_recipe_process
    @recipe_process = RecipeProcess.new(recipe_process_params)

    if @recipe_process.save
      redirect_to settings_system_path, notice: '공정이 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @equipment_types = EquipmentType.all
      @recipe_processes = RecipeProcess.all
      @shipment_purpose = ShipmentPurpose.new
      @shipment_requester = ShipmentRequester.new
      @equipment_type = EquipmentType.new
      @equipment_mode = EquipmentMode.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_recipe_process
    @recipe_process = RecipeProcess.find(params[:id])
    @recipe_process.destroy
    redirect_to settings_system_path, notice: '공정이 삭제되었습니다.'
  end

  def update_recipe_process_positions
    params[:positions].each_with_index do |id, index|
      RecipeProcess.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  def update_gijeongddeok_defaults
    @gijeongddeok_default = GijeongddeokDefault.instance

    if @gijeongddeok_default.update(gijeongddeok_default_params)
      redirect_to settings_system_path, notice: '기정떡 기본값이 저장되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @equipment_types = EquipmentType.all
      @recipe_processes = RecipeProcess.all
      @shipment_purpose = ShipmentPurpose.new
      @shipment_requester = ShipmentRequester.new
      @equipment_type = EquipmentType.new
      @equipment_mode = EquipmentMode.new
      @recipe_process = RecipeProcess.new
      render :system, status: :unprocessable_entity
    end
  end

  def update_gijeongddeok_field_positions
    params[:positions].each_with_index do |id, index|
      GijeongddeokFieldOrder.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  private

  def shipment_purpose_params
    params.require(:shipment_purpose).permit(:name)
  end

  def shipment_requester_params
    params.require(:shipment_requester).permit(:name)
  end

  def equipment_type_params
    params.require(:equipment_type).permit(:name)
  end

  def equipment_mode_params
    params.require(:equipment_mode).permit(:name, :equipment_type_id)
  end

  def recipe_process_params
    params.require(:recipe_process).permit(:name)
  end

  def gijeongddeok_default_params
    params.require(:gijeongddeok_default).permit(
      :fermentation_room_temp, :refrigeration_room_temp,
      :water_temp, :flour_temp, :porridge_temp, :dough_temp,
      :yeast_amount, :steiva_amount, :salt_amount, :sugar_amount,
      :water_amount, :dough_count, :makgeolli_consumption
    )
  end
end
