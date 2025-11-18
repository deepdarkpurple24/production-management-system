class CreateItemCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :item_categories do |t|
      t.string :name, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :item_categories, :name, unique: true
    add_index :item_categories, :position

    # 기본 카테고리 데이터
    ItemCategory.create!([
      { name: '원자재', position: 1 },
      { name: '부자재', position: 2 },
      { name: '완제품', position: 3 }
    ])
  end
end
