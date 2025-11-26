class FinishedProductsController < ApplicationController
  before_action :set_finished_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @finished_products = FinishedProduct.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @finished_product = FinishedProduct.new
    @finished_product.finished_product_recipes.build
    @recipes = Recipe.all.order(:name)
  end

  def edit
    @recipes = Recipe.all.order(:name)
  end

  def create
    @finished_product = FinishedProduct.new(finished_product_params)

    if @finished_product.save
      redirect_to finished_products_path, notice: "완제품이 성공적으로 등록되었습니다."
    else
      @recipes = Recipe.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @finished_product.update(finished_product_params)
      redirect_to finished_products_path, notice: "완제품 정보가 수정되었습니다."
    else
      @recipes = Recipe.all.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @finished_product.destroy
    redirect_to finished_products_path, notice: "완제품이 삭제되었습니다."
  end

  private

  def set_finished_product
    @finished_product = FinishedProduct.find(params[:id])
  end

  def finished_product_params
    params.require(:finished_product).permit(
      :name,
      :weight,
      :weight_unit,
      :description,
      :notes,
      finished_product_recipes_attributes: [ :id, :recipe_id, :quantity, :notes, :position, :_destroy ]
    )
  end
end
