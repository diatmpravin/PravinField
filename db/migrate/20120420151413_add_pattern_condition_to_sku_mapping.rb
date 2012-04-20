class AddPatternConditionToSkuMapping < ActiveRecord::Migration
  def change
    add_column :sku_mappings, :pattern_condition, :string
  end
end
