class AddSku2ToProduct < ActiveRecord::Migration
  def change
    add_column :products, :sku2, :string
  end
end
