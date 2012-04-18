class DropProductsStores < ActiveRecord::Migration
  def change
    drop_table :products_stores
  end
end
