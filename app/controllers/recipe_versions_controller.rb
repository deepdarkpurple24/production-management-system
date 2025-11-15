class RecipeVersionsController < ApplicationController
  before_action :set_recipe

  def index
    @versions = @recipe.recipe_versions.order(version_number: :desc)
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end
end
