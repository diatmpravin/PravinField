class CreateProductsStores < ActiveRecord::Migration
  def change
    create_table :products_stores do |t|
      t.integer :product_id
      t.integer :store_id
      t.string :handle
      t.string :foreign_id

      t.timestamps
    end
  end
end