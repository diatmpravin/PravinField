class AddImage2ToVariantImages < ActiveRecord::Migration

  def self.up
    change_table :variant_images do |t|
      t.has_attached_file :image2
    end
  end

  def self.down
    drop_attached_file :variant_images, :image2
  end

end
