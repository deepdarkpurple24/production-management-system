# frozen_string_literal: true

class Admin::SettingsController < Admin::BaseController
  def index
    # 시스템 설정
    @session_timeout_minutes = SystemSetting.session_timeout_minutes
    @session_warning_seconds = SystemSetting.session_warning_seconds

    # 기존 설정 데이터
    @shipment_purposes = ShipmentPurpose.all
    @equipment_types = EquipmentType.all
    @recipe_processes = RecipeProcess.all
    @item_categories = ItemCategory.all
    @storage_locations = StorageLocation.all
    @shipment_purpose = ShipmentPurpose.new
    @equipment_type = EquipmentType.new
    @equipment_mode = EquipmentMode.new
    @recipe_process = RecipeProcess.new
    @item_category = ItemCategory.new
    @storage_location = StorageLocation.new
    @gijeongddeok_default = GijeongddeokDefault.instance
    @gijeongddeok_fields = GijeongddeokFieldOrder.all
    @page_permissions = PagePermission.ordered

    # 0.5통 추가 재료 설정용 재료 품목 목록
    @ingredient_items = Item.order(:name)

    # 기본 완제품 선택용
    @finished_products = FinishedProduct.order(:name)
  end

  # 시스템 설정 업데이트
  def update_system
    SystemSetting.set("session_timeout_minutes", params[:session_timeout_minutes])
    SystemSetting.set("session_warning_seconds", params[:session_warning_seconds])

    redirect_to admin_settings_path(tab: "system"), notice: "시스템 설정이 저장되었습니다."
  end

  # 출고 목적 관리
  def create_purpose
    @shipment_purpose = ShipmentPurpose.new(shipment_purpose_params)

    if @shipment_purpose.save
      redirect_to admin_settings_path(tab: "inventory"), notice: "출고 목적이 추가되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy_purpose
    @shipment_purpose = ShipmentPurpose.find(params[:id])
    @shipment_purpose.destroy
    redirect_to admin_settings_path(tab: "inventory"), notice: "출고 목적이 삭제되었습니다."
  end

  def update_purpose_positions
    params[:positions].each_with_index do |id, index|
      ShipmentPurpose.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  # 장비 구분 관리
  def create_equipment_type
    @equipment_type = EquipmentType.new(equipment_type_params)

    if @equipment_type.save
      redirect_to admin_settings_path(tab: "equipment"), notice: "장비 구분이 추가되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy_equipment_type
    @equipment_type = EquipmentType.find(params[:id])
    @equipment_type.destroy
    redirect_to admin_settings_path(tab: "equipment"), notice: "장비 구분이 삭제되었습니다."
  end

  def update_equipment_type_positions
    params[:positions].each_with_index do |id, index|
      EquipmentType.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  # 장비 모드 관리
  def create_equipment_mode
    @equipment_mode = EquipmentMode.new(equipment_mode_params)

    if @equipment_mode.save
      redirect_to admin_settings_path(tab: "equipment"), notice: "장비 모드가 추가되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy_equipment_mode
    @equipment_mode = EquipmentMode.find(params[:id])
    @equipment_mode.destroy
    redirect_to admin_settings_path(tab: "equipment"), notice: "장비 모드가 삭제되었습니다."
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

  # 공정 관리
  def create_recipe_process
    @recipe_process = RecipeProcess.new(recipe_process_params)

    if @recipe_process.save
      redirect_to admin_settings_path(tab: "recipe"), notice: "공정이 추가되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy_recipe_process
    @recipe_process = RecipeProcess.find(params[:id])
    @recipe_process.destroy
    redirect_to admin_settings_path(tab: "recipe"), notice: "공정이 삭제되었습니다."
  end

  def update_recipe_process_positions
    params[:positions].each_with_index do |id, index|
      RecipeProcess.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  # 기정떡 기본 완제품 설정 (단일 - 레거시)
  def update_gijeongddeok_default_product
    @gijeongddeok_default = GijeongddeokDefault.instance
    product_id = params[:default_finished_product_id].presence

    if @gijeongddeok_default.update(default_finished_product_id: product_id)
      redirect_to admin_settings_path(tab: "production"), notice: "기정떡 기본 완제품이 저장되었습니다."
    else
      redirect_to admin_settings_path(tab: "production"), alert: "저장 중 오류가 발생했습니다."
    end
  end

  # 기정떡 기본 완제품 설정 (다중)
  def update_gijeongddeok_default_products
    @gijeongddeok_default = GijeongddeokDefault.instance
    product_ids = params[:default_finished_product_ids] || []

    if @gijeongddeok_default.update(default_finished_product_ids: product_ids)
      redirect_to admin_settings_path(tab: "production"), notice: "기정떡 기본 완제품이 저장되었습니다."
    else
      redirect_to admin_settings_path(tab: "production"), alert: "저장 중 오류가 발생했습니다."
    end
  end

  # 기정떡 기본값
  def update_gijeongddeok_defaults
    @gijeongddeok_default = GijeongddeokDefault.instance

    field_params = params.require(:gijeongddeok_default)
    field_params.each do |field_name, value|
      @gijeongddeok_default.write_field(field_name, value)
    end

    if @gijeongddeok_default.save
      redirect_to admin_settings_path(tab: "production"), notice: "기정떡 기본값이 저장되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
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

    if @field.field_name.blank?
      base_name = @field.label.downcase
                              .gsub(/[^a-z0-9가-힣\s]/, "")
                              .gsub(/\s+/, "_")

      if base_name =~ /[가-힣]/
        prefix = case @field.category
        when "temperature" then "temp"
        when "ingredient" then "ingredient"
        when "makgeolli" then "makgeolli"
        else "custom"
        end

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
      redirect_to admin_settings_path(tab: "production"), notice: "필드가 추가되었습니다."
    else
      redirect_to admin_settings_path(tab: "production"), alert: "필드 추가 실패: #{@field.errors.full_messages.join(', ')}"
    end
  end

  def destroy_gijeongddeok_field
    @field = GijeongddeokFieldOrder.find(params[:id])
    @field.destroy
    redirect_to admin_settings_path(tab: "production"), notice: "필드가 삭제되었습니다."
  end

  # 0.5통 추가 재료 설정
  def update_half_batch_ingredients
    @gijeongddeok_default = GijeongddeokDefault.instance

    ingredients = []
    if params[:half_batch_ingredients].present?
      params[:half_batch_ingredients].each do |_index, ingredient|
        next if ingredient[:item_id].blank?

        ingredients << {
          item_id: ingredient[:item_id].to_i,
          weight: ingredient[:weight].to_f
        }
      end
    end

    @gijeongddeok_default.half_batch_extra_ingredients = ingredients

    if @gijeongddeok_default.save
      redirect_to admin_settings_path(tab: "production"), notice: "0.5통 추가 재료 설정이 저장되었습니다."
    else
      redirect_to admin_settings_path(tab: "production"), alert: "설정 저장에 실패했습니다."
    end
  end

  # 품목 카테고리 관리
  def create_item_category
    @item_category = ItemCategory.new(item_category_params)

    if @item_category.save
      redirect_to admin_settings_path(tab: "inventory"), notice: "품목 카테고리가 추가되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy_item_category
    @item_category = ItemCategory.find(params[:id])
    @item_category.destroy
    redirect_to admin_settings_path(tab: "inventory"), notice: "품목 카테고리가 삭제되었습니다."
  end

  def update_item_category_positions
    params[:positions].each_with_index do |id, index|
      ItemCategory.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  # 보관위치 관리
  def create_storage_location
    @storage_location = StorageLocation.new(storage_location_params)

    if @storage_location.save
      redirect_to admin_settings_path(tab: "inventory"), notice: "보관위치가 추가되었습니다."
    else
      load_settings_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy_storage_location
    @storage_location = StorageLocation.find(params[:id])
    @storage_location.destroy
    redirect_to admin_settings_path(tab: "inventory"), notice: "보관위치가 삭제되었습니다."
  end

  def update_storage_location_positions
    params[:positions].each_with_index do |id, index|
      StorageLocation.unscoped.find(id).update_column(:position, index + 1)
    end
    head :ok
  end

  # 페이지 권한 관리
  def update_page_permission
    @page_permission = PagePermission.find(params[:id])
    @page_permission.update(allowed_for_users: params[:allowed_for_users])
    redirect_to admin_settings_path(tab: "permissions"), notice: "페이지 권한이 변경되었습니다."
  end

  def update_page_permissions_batch
    PagePermission.update_all(allowed_for_users: false, allowed_for_sub_admins: false)

    if params[:permissions_users].present?
      params[:permissions_users].each do |id, allowed|
        PagePermission.find(id).update(allowed_for_users: allowed == "1")
      end
    end

    if params[:permissions_sub_admins].present?
      params[:permissions_sub_admins].each do |id, allowed|
        PagePermission.find(id).update(allowed_for_sub_admins: allowed == "1")
      end
    end

    redirect_to admin_settings_path(tab: "permissions"), notice: "페이지 권한이 저장되었습니다."
  end

  private

  def load_settings_data
    @session_timeout_minutes = SystemSetting.session_timeout_minutes
    @session_warning_seconds = SystemSetting.session_warning_seconds
    @shipment_purposes = ShipmentPurpose.all
    @equipment_types = EquipmentType.all
    @recipe_processes = RecipeProcess.all
    @item_categories = ItemCategory.all
    @storage_locations = StorageLocation.all
    @shipment_purpose ||= ShipmentPurpose.new
    @equipment_type ||= EquipmentType.new
    @equipment_mode ||= EquipmentMode.new
    @recipe_process ||= RecipeProcess.new
    @item_category ||= ItemCategory.new
    @storage_location ||= StorageLocation.new
    @gijeongddeok_default = GijeongddeokDefault.instance
    @gijeongddeok_fields = GijeongddeokFieldOrder.all
    @page_permissions = PagePermission.ordered
    @ingredient_items = Item.order(:name)
    @finished_products = FinishedProduct.order(:name)
  end

  def shipment_purpose_params
    params.require(:shipment_purpose).permit(:name)
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
