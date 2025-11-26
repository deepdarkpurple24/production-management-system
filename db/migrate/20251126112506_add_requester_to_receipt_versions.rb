class AddRequesterToReceiptVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :receipt_versions, :requester, :string
  end
end
