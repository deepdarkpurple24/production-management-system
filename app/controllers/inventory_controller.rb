class InventoryController < ApplicationController
  def index
    redirect_to inventory_receipts_path
  end
end
