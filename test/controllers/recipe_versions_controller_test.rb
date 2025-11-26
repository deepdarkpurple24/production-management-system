require "test_helper"

class RecipeVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recipe = recipes(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get recipe_recipe_versions_url(@recipe)
    assert_response :success
  end
end
