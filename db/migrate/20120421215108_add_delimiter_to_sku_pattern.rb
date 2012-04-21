class AddDelimiterToSkuPattern < ActiveRecord::Migration
  def change
    add_column :sku_patterns, :delimiter, :string, :default=>'-'
  end
end
