class Inventory::OpenedItemsController < ApplicationController
  def index
    @opened_items = OpenedItem
      .includes(:item, :receipt)
      .available
      .by_expiration

    # 품목별로 그룹화하여 통계 제공
    @items_summary = OpenedItem
      .available
      .joins(:item)
      .group("items.id", "items.name")
      .select("items.id as item_id, items.name as item_name, COUNT(*) as opened_count, SUM(opened_items.remaining_weight) as total_weight")
      .order("items.name")
  end
end
