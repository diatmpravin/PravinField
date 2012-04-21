class CreateImportProducts < ActiveRecord::Migration
  def change
    create_table :import_products do |t|
      t.string :name
      t.text :description
      t.date :available_on
      t.date :deleted_at
      t.text :meta_description
      t.string :meta_keywords
      t.integer :brand_id
      t.string :sku
      t.string :category
      t.string :product_type
      t.string :variation_theme
      t.string :department
      t.date :file_date
      t.string :amazon_template
      t.text :keywords
      t.text :keywords

      t.timestamps
    end
  end
end
