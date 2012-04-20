class AddSkuMapableToSkuMappings < ActiveRecord::Migration
  def change
    rename_column :sku_mappings, :foreign_id, :sku_mapable_id
    rename_column :sku_mappings, :granularity, :sku_mapable_type
    add_column :sku_mappings, :pattern_for, :string
  end
end
