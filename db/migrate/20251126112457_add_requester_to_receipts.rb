class AddRequesterToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :requester, :string
  end
end
