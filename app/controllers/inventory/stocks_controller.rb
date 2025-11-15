class Inventory::StocksController < ApplicationController
  def index
    @items = Item.all.order(:name)
  end
end
