class RenameBaseSkuToSku < ActiveRecord::Migration
  def change
    rename_column :products, :base_sku, :sku
  end
end
