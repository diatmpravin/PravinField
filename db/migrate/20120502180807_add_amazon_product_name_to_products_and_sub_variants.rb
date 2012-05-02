class AddAmazonProductNameToProductsAndSubVariants < ActiveRecord::Migration
  def change
    add_column :products, :amazon_name, :string
    add_column :sub_variants, :amazon_name, :string
    remove_column :variants, :amazon_product_name
    add_column :products, :amazon_description, :string
    rename_column :variants, :amazon_product_description, :amazon_description
    remove_column :variants, :amazon_product_id
  end
end
