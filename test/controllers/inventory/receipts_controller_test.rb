require "test_helper"

class Inventory::ReceiptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @receipt = receipts(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get inventory_receipts_url
    assert_response :success
  end

  test "should get new" do
    get new_inventory_receipt_url
    assert_response :success
  end

  test "should create receipt" do
    assert_difference("Receipt.count") do
      post inventory_receipts_url, params: {
        receipt: {
          item_id: items(:one).id,
          receipt_date: Date.today,
          quantity: 100,
          unit_price: 1000
        }
      }
    end

    assert_redirected_to inventory_receipts_url
  end

  test "should show receipt" do
    get inventory_receipt_url(@receipt)
    assert_response :success
  end

  test "should get edit" do
    get edit_inventory_receipt_url(@receipt)
    assert_response :success
  end

  test "should update receipt" do
    patch inventory_receipt_url(@receipt), params: { receipt: { quantity: @receipt.quantity } }
    assert_redirected_to inventory_receipts_url
  end

  test "should destroy receipt" do
    assert_difference("Receipt.count", -1) do
      delete inventory_receipt_url(@receipt)
    end

    assert_redirected_to inventory_receipts_url
  end
end
