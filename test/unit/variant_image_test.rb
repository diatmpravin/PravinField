require 'test_helper'

class VariantImageTest < ActiveSupport::TestCase

	test "unique image file name should be unique" do
		vi = FactoryGirl.create(:variant_image, :unique_image_file_name => 'http://cdn.shopify.com/s/files/1/0109/9112/t/4/assets/logo.png')
		assert vi.valid?
		vi2 = FactoryGirl.build(:variant_image, :unique_image_file_name => vi.unique_image_file_name, :variant => vi.variant)
		assert vi2.invalid?
	end

	test "image upload should work via remote URL" do
		vi = FactoryGirl.create(:variant_image, :unique_image_file_name => 'http://cdn.shopify.com/s/files/1/0109/9112/t/4/assets/logo.png' )
		assert vi.valid?
		assert_equal 300, vi.image_width
		assert_equal 60, vi.image_height
		assert_equal 7447, vi.image_file_size
		assert_equal 'image/png', vi.image_content_type
		assert_equal 'logo.png', vi.image_file_name
		assert_equal 'http://cdn.shopify.com/s/files/1/0109/9112/t/4/assets/logo.png', vi.unique_image_file_name 
	end

end
