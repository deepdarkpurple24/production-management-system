class CreateStorageLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :storage_locations do |t|
      t.string :name, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :storage_locations, :name, unique: true
    add_index :storage_locations, :position

    # 기본 보관위치 데이터
    StorageLocation.create!([
      { name: '창고 A', position: 1 },
      { name: '창고 B', position: 2 },
      { name: '냉장고', position: 3 },
      { name: '냉동고', position: 4 }
    ])
  end
end
