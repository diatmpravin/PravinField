class RenameKeywordFields < ActiveRecord::Migration
  def change
    rename_column :products, :keywords, :style_keywords
    rename_column :products, :keywords2, :occasion_lifestyle_keywords
    rename_column :products, :keywords3, :search_keywords
    add_column :products, :bullet_points, :text
    remove_column :products, :sku2
    
    
  end
end
