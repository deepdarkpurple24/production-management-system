require "test_helper"

class RecipeVersionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get recipe_versions_index_url
    assert_response :success
  end
end
