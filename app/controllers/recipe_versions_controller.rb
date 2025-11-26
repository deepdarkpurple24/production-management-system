class RecipeVersionsController < ApplicationController
  before_action :set_recipe
  before_action :set_version, only: [ :destroy ]

  def index
    @versions = @recipe.recipe_versions.order(version_number: :desc)
  end

  def destroy
    @version.destroy
    redirect_to recipe_recipe_versions_path(@recipe), notice: "수정내역이 삭제되었습니다."
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def set_version
    @version = @recipe.recipe_versions.find(params[:id])
  end
end
