require "test_helper"

class Inventory::ReceiptsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get inventory_receipts_index_url
    assert_response :success
  end

  test "should get show" do
    get inventory_receipts_show_url
    assert_response :success
  end

  test "should get new" do
    get inventory_receipts_new_url
    assert_response :success
  end

  test "should get edit" do
    get inventory_receipts_edit_url
    assert_response :success
  end
end
