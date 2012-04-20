class AddImageHeightToVariantImages < ActiveRecord::Migration
  def change
    add_column :variant_images, :image_height, :integer
  end
end
