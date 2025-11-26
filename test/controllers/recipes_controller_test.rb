require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recipe = recipes(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get recipes_url
    assert_response :success
  end

  test "should get new" do
    get new_recipe_url
    assert_response :success
  end

  test "should create recipe" do
    assert_difference("Recipe.count") do
      post recipes_url, params: { recipe: { name: "Test Recipe", description: "Test description" } }
    end

    assert_redirected_to recipes_url
  end

  test "should show recipe" do
    get recipe_url(@recipe)
    assert_response :success
  end

  test "should get edit" do
    get edit_recipe_url(@recipe)
    assert_response :success
  end

  test "should update recipe" do
    patch recipe_url(@recipe), params: { recipe: { name: @recipe.name } }
    assert_redirected_to recipes_url
  end

  test "should not destroy recipe when used in finished products" do
    # Recipe :one is used in finished_product :one via fixture
    assert_no_difference("Recipe.count") do
      delete recipe_url(@recipe)
    end

    assert_redirected_to recipes_url
    assert_match /완제품에서 사용 중/, flash[:alert]
  end
end
