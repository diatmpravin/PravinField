require 'test_helper'

class VariantImageTest < ActiveSupport::TestCase

  IMAGE_FILE_NAME = 'logo.png'
  REMOTE_IMAGE_PATH = 'http://cdn.shopify.com/s/files/1/0109/9112/t/4/assets/'+IMAGE_FILE_NAME

  #https://cdn.shopify.com/s/files/1/0109/9112/products/adidas_originals_abasto_ah24-6054_large.jpeg?15304
  #https://cdn.shopify.com/s/files/1/0109/9112/products/adidas_originals_abasto_ah24-6056_large.jpeg?15304
  #https://cdn.shopify.com/s/files/1/0109/9112/products/adidas_originals_abasto_ah24-6055_large.jpeg?15304
  #https://cdn.shopify.com/s/files/1/0109/9112/products/adidas_originals_abasto_ah24-6057_large.jpeg?15304
  
  
  LOCAL_IMAGE_PATH = 'test/fixtures/images/'+IMAGE_FILE_NAME

	test "unique image file name should be unique" do
		vi = FactoryGirl.create(:variant_image, :unique_image_file_name => REMOTE_IMAGE_PATH )
		assert vi.valid?
		vi2 = FactoryGirl.build(:variant_image, :unique_image_file_name => vi.unique_image_file_name, :variant_id => vi.variant_id)
		assert vi2.invalid?
	end

	test "image upload should work via remote URL" do
		vi = FactoryGirl.create(:variant_image, :unique_image_file_name => REMOTE_IMAGE_PATH )
		assert vi.valid?
		assert_equal REMOTE_IMAGE_PATH, vi.unique_image_file_name 		
		assert_equal 300, vi.image_width # we know logo.png is 300x60
		assert_equal 60, vi.image_height
		
		# Confirm primary image was saved
		assert_equal 7447, vi.image_file_size # we know logo.png is 7kb
		assert_equal 'image/png', vi.image_content_type
		assert_equal IMAGE_FILE_NAME, vi.image_file_name

    # Confirm image was replicated to second server
		assert_equal 7447, vi.image2_file_size
		assert_equal 'image/png', vi.image2_content_type
		assert_equal IMAGE_FILE_NAME, vi.image2_file_name
	end
		
end
