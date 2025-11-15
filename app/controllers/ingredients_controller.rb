class IngredientsController < ApplicationController
  before_action :set_ingredient, only: [:show, :edit, :update, :destroy]

  def index
    @ingredients = Ingredient.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @ingredient = Ingredient.new
    @ingredient.ingredient_items.build # 초기 빈 품목 행 추가
    @items = Item.all.order(:name)
    @ingredients = Ingredient.all.order(:name)
    @equipment_types = EquipmentType.all.order(:position)
  end

  def edit
    @items = Item.all.order(:name)
    @ingredients = Ingredient.where.not(id: @ingredient.id).order(:name) # 자기 자신 제외
    @equipment_types = EquipmentType.all.order(:position)
  end

  def create
    @ingredient = Ingredient.new(ingredient_params)

    if @ingredient.save
      redirect_to ingredients_path, notice: '재료가 성공적으로 등록되었습니다.'
    else
      @items = Item.all.order(:name)
      @ingredients = Ingredient.all.order(:name)
      @equipment_types = EquipmentType.all.order(:position)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @ingredient.update(ingredient_params)
      redirect_to ingredients_path, notice: '재료 정보가 수정되었습니다.'
    else
      @items = Item.all.order(:name)
      @ingredients = Ingredient.where.not(id: @ingredient.id).order(:name)
      @equipment_types = EquipmentType.all.order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ingredient.destroy
    redirect_to ingredients_path, notice: '재료가 삭제되었습니다.'
  end

  private

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(
      :name,
      :description,
      :notes,
      :production_quantity,
      :production_unit,
      :equipment_type_id,
      :equipment_mode_id,
      :cooking_time,
      ingredient_items_attributes: [
        :id, :item_id, :referenced_ingredient_id, :source_type, :custom_name,
        :quantity, :unit, :row_type, :notes, :position, :_destroy
      ]
    )
  end
end
