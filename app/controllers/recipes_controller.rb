class RecipesController < ApplicationController
  before_action :set_recipe, only: [:show, :edit, :update, :destroy, :update_ingredient_positions]

  def index
    @recipes = Recipe.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @recipe = Recipe.new
    @recipe.recipe_ingredients.build # 초기 빈 재료 행 추가
    @items = Item.all.order(:name)
    @equipments = Equipment.all.order(:name)
    @recipe_processes = RecipeProcess.all
  end

  def edit
    @items = Item.all.order(:name)
    @equipments = Equipment.all.order(:name)
    @recipe_processes = RecipeProcess.all
  end

  def create
    @recipe = Recipe.new(recipe_params)

    if @recipe.save
      redirect_to recipes_path, notice: '레시피가 성공적으로 등록되었습니다.'
    else
      @items = Item.all.order(:name)
      @equipments = Equipment.all.order(:name)
      @recipe_processes = RecipeProcess.all
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to recipes_path, notice: '레시피 정보가 수정되었습니다.'
    else
      @items = Item.all.order(:name)
      @equipments = Equipment.all.order(:name)
      @recipe_processes = RecipeProcess.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 완제품에서 사용 중인지 확인
    if @recipe.finished_products.any?
      product_names = @recipe.finished_products.map(&:name).join(', ')
      redirect_to recipes_path, alert: "이 레시피는 다음 완제품에서 사용 중입니다: #{product_names}. 먼저 완제품에서 레시피를 제거해주세요."
    else
      @recipe.destroy
      redirect_to recipes_path, notice: '레시피가 삭제되었습니다.'
    end
  end

  def update_ingredient_positions
    params[:positions].each_with_index do |id, index|
      @recipe.recipe_ingredients.find(id).update_column(:position, index)
    end
    head :ok
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(
      :name,
      :description,
      :notes,
      recipe_ingredients_attributes: [:id, :item_id, :weight, :is_main, :row_type, :notes, :position, :_destroy],
      recipe_equipments_attributes: [:id, :equipment_id, :work_capacity, :work_capacity_unit, :position, :row_type, :process_id, :_destroy]
    )
  end
end
