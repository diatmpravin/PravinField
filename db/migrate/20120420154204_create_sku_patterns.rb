class CreateSkuPatterns < ActiveRecord::Migration
  def change
    create_table :sku_patterns do |t|
      t.integer :brand_id
      t.string :pattern
      t.string :condition
      t.string :granularity, :default=>'Variant'
      t.float :priority

      t.timestamps
    end
    remove_column :sku_mappings, :pattern_for
    remove_column :sku_mappings, :pattern_condition
  end
end
