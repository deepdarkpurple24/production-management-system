class SettingsController < ApplicationController
  def index
    # 메인 설정 페이지 (버튼만 표시)
  end

  def system
    @shipment_purposes = ShipmentPurpose.all
    @shipment_requesters = ShipmentRequester.all
    @equipment_types = EquipmentType.all
    @recipe_processes = RecipeProcess.all
    @item_categories = ItemCategory.all
    @storage_locations = StorageLocation.all
    @shipment_purpose = ShipmentPurpose.new
    @shipment_requester = ShipmentRequester.new
    @equipment_type = EquipmentType.new
    @equipment_mode = EquipmentMode.new
    @recipe_process = RecipeProcess.new
    @item_category = ItemCategory.new
    @storage_location = StorageLocation.new
    @gijeongddeok_default = GijeongddeokDefault.instance
    @gijeongddeok_fields = GijeongddeokFieldOrder.all
  end

  def create_purpose
    @shipment_purpose = ShipmentPurpose.new(shipment_purpose_params)

    if @shipment_purpose.save
      redirect_to settings_system_path(tab: 'inventory'), notice: '출고 목적이 추가되었습니다.'
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
    redirect_to settings_system_path(tab: 'inventory'), notice: '출고 목적이 삭제되었습니다.'
  end

  def create_requester
    @shipment_requester = ShipmentRequester.new(shipment_requester_params)

    if @shipment_requester.save
      redirect_to settings_system_path(tab: 'inventory'), notice: '출고 요청자가 추가되었습니다.'
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
    redirect_to settings_system_path(tab: 'inventory'), notice: '출고 요청자가 삭제되었습니다.'
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
      redirect_to settings_system_path(tab: 'equipment'), notice: '장비 구분이 추가되었습니다.'
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
    redirect_to settings_system_path(tab: 'equipment'), notice: '장비 구분이 삭제되었습니다.'
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
      redirect_to settings_system_path(tab: 'equipment'), notice: '장비 모드가 추가되었습니다.'
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
    redirect_to settings_system_path(tab: 'equipment'), notice: '장비 모드가 삭제되었습니다.'
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
      redirect_to settings_system_path(tab: 'recipe'), notice: '공정이 추가되었습니다.'
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
    redirect_to settings_system_path(tab: 'recipe'), notice: '공정이 삭제되었습니다.'
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
      redirect_to settings_system_path(tab: 'production'), notice: '기정떡 기본값이 저장되었습니다.'
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

  def create_gijeongddeok_field
    @field = GijeongddeokFieldOrder.new(gijeongddeok_field_params)
    @field.position = GijeongddeokFieldOrder.maximum(:position).to_i + 1

    # 필드명이 비어있으면 라벨로부터 자동 생성
    if @field.field_name.blank?
      base_name = @field.label.downcase
                              .gsub(/[^a-z0-9가-힣\s]/, '') # 특수문자 제거
                              .gsub(/\s+/, '_')              # 공백을 언더스코어로

      # 한글이 포함된 경우 간단한 영문 변환 (카테고리 기반)
      if base_name =~ /[가-힣]/
        prefix = case @field.category
                 when 'temperature' then 'temp'
                 when 'ingredient' then 'ingredient'
                 when 'makgeolli' then 'makgeolli'
                 else 'custom'
                 end

        # 유니크한 이름 생성
        counter = 1
        field_name = "#{prefix}_#{counter}"
        while GijeongddeokFieldOrder.exists?(field_name: field_name)
          counter += 1
          field_name = "#{prefix}_#{counter}"
        end
        @field.field_name = field_name
      else
        @field.field_name = base_name
      end
    end

    if @field.save
      redirect_to settings_system_path(tab: 'production'), notice: '필드가 추가되었습니다.'
    else
      redirect_to settings_system_path(tab: 'production'), alert: "필드 추가 실패: #{@field.errors.full_messages.join(', ')}"
    end
  end

  def destroy_gijeongddeok_field
    @field = GijeongddeokFieldOrder.find(params[:id])
    @field.destroy
    redirect_to settings_system_path(tab: 'production'), notice: '필드가 삭제되었습니다.'
  end

  def create_item_category
    @item_category = ItemCategory.new(item_category_params)

    if @item_category.save
      redirect_to settings_system_path(tab: 'inventory'), notice: '품목 카테고리가 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @equipment_types = EquipmentType.all
      @recipe_processes = RecipeProcess.all
      @item_categories = ItemCategory.all
      @shipment_purpose = ShipmentPurpose.new
      @shipment_requester = ShipmentRequester.new
      @equipment_type = EquipmentType.new
      @equipment_mode = EquipmentMode.new
      @recipe_process = RecipeProcess.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_item_category
    @item_category = ItemCategory.find(params[:id])
    @item_category.destroy
    redirect_to settings_system_path(tab: 'inventory'), notice: '품목 카테고리가 삭제되었습니다.'
  end

  def update_item_category_positions
    params[:positions].each_with_index do |id, index|
      ItemCategory.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  def create_storage_location
    @storage_location = StorageLocation.new(storage_location_params)

    if @storage_location.save
      redirect_to settings_system_path(tab: 'inventory'), notice: '보관위치가 추가되었습니다.'
    else
      @shipment_purposes = ShipmentPurpose.all
      @shipment_requesters = ShipmentRequester.all
      @equipment_types = EquipmentType.all
      @recipe_processes = RecipeProcess.all
      @item_categories = ItemCategory.all
      @storage_locations = StorageLocation.all
      @shipment_purpose = ShipmentPurpose.new
      @shipment_requester = ShipmentRequester.new
      @equipment_type = EquipmentType.new
      @equipment_mode = EquipmentMode.new
      @recipe_process = RecipeProcess.new
      @item_category = ItemCategory.new
      render :system, status: :unprocessable_entity
    end
  end

  def destroy_storage_location
    @storage_location = StorageLocation.find(params[:id])
    @storage_location.destroy
    redirect_to settings_system_path(tab: 'inventory'), notice: '보관위치가 삭제되었습니다.'
  end

  def update_storage_location_positions
    params[:positions].each_with_index do |id, index|
      StorageLocation.unscoped.find(id).update_column(:position, index + 1)
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
    # 동적으로 모든 필드명 허용 (사용자가 추가한 커스텀 필드 포함)
    field_names = GijeongddeokFieldOrder.pluck(:field_name).map(&:to_sym)
    params.require(:gijeongddeok_default).permit(*field_names)
  end

  def gijeongddeok_field_params
    params.require(:gijeongddeok_field_order).permit(:field_name, :label, :category, :unit)
  end

  def item_category_params
    params.require(:item_category).permit(:name)
  end

  def storage_location_params
    params.require(:storage_location).permit(:name)
  end
end
