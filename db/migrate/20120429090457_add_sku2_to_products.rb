class AddSku2ToProducts < ActiveRecord::Migration
  def change
    add_column :products, :sku2, :string
  end
end
