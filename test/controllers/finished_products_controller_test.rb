require "test_helper"

class FinishedProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get finished_products_index_url
    assert_response :success
  end

  test "should get show" do
    get finished_products_show_url
    assert_response :success
  end

  test "should get new" do
    get finished_products_new_url
    assert_response :success
  end

  test "should get edit" do
    get finished_products_edit_url
    assert_response :success
  end

  test "should get create" do
    get finished_products_create_url
    assert_response :success
  end

  test "should get update" do
    get finished_products_update_url
    assert_response :success
  end

  test "should get destroy" do
    get finished_products_destroy_url
    assert_response :success
  end
end
