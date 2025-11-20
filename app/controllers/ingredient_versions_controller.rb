class IngredientVersionsController < ApplicationController
  before_action :set_ingredient
  before_action :set_version, only: [:destroy]

  def index
    @versions = @ingredient.ingredient_versions.order(version_number: :desc)
  end

  def destroy
    @version.destroy
    redirect_to ingredient_ingredient_versions_path(@ingredient), notice: '수정내역이 삭제되었습니다.'
  end

  private

  def set_ingredient
    @ingredient = Ingredient.find(params[:ingredient_id])
  end

  def set_version
    @version = @ingredient.ingredient_versions.find(params[:id])
  end
end
