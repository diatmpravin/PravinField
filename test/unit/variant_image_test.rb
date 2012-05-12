require 'test_helper'

class VariantImageTest < ActiveSupport::TestCase

	test "unique image file name should be unique" do
		vi = FactoryGirl.create(:variant_image, :unique_image_file_name => REMOTE_IMAGE)
		assert vi.valid?
		vi2 = FactoryGirl.build(:variant_image, :unique_image_file_name => vi.unique_image_file_name, :variant_id => vi.variant_id)
		assert vi2.invalid?
		assert vi2.errors[:unique_image_file_name].any?
	end
	
	test "unique image file name should be unique across variants of a product" do
	  p = FactoryGirl.create(:product)
	  v = FactoryGirl.create(:variant, :product_id=>p.id)
	  v2 = FactoryGirl.create(:variant, :product_id=>p.id)
	  v3 = FactoryGirl.create(:variant, :product_id=>p.id)
	  assert v.is_master
	  assert !v2.is_master  
	  assert_equal v, p.master
	  
	  vi = FactoryGirl.create(:variant_image, :variant_id => v.id, :unique_image_file_name => REMOTE_IMAGE)
	  vi2 = FactoryGirl.build(:variant_image, :variant_id => v2.id, :unique_image_file_name => REMOTE_IMAGE)
	  assert vi2.invalid?
	  assert vi2.errors[:unique_image_file_name].any?
	  assert !v2.variant_images.any?
	  
	  vi2.unique_image_file_name = LOCAL_IMAGE
	  assert vi2.valid?
	  vi2.save
	  
	  # Still valid because this image was not associated with the master variant, so we have to save it
	  vi3 = FactoryGirl.build(:variant_image, :variant_id => v3.id, :unique_image_file_name => LOCAL_IMAGE)
	  assert vi3.valid?

	  # Add the local image to the master variant
	  vi4 = FactoryGirl.create(:variant_image, :variant_id => v3.id, :unique_image_file_name => LOCAL_IMAGE)
	  
	  # Now, that it has been added to the master, the unsaved variant image is invalid
	  assert vi3.invalid?
	  
	  # But because vi2 was previously saved, this validation does not run for updates, so it is not invalid now
	  assert vi2.reload.valid?
	end
	
	test "404 URL not found should not create a variant image" do
	  vi = FactoryGirl.build(:variant_image, :unique_image_file_name => REMOTE_IMAGE+'g')
	  assert vi.invalid?
	  assert vi.errors[:unique_image_file_name].any?
	end
	
	test "blank remote URL should not create a variant image" do
	  vi = FactoryGirl.build(:variant_image, :image_file_name=>nil, :unique_image_file_name=>nil)
	  assert vi.invalid?
	  assert vi.errors[:unique_image_file_name].any?
	end

	test "image upload should work via remote URL" do
		vi = FactoryGirl.build(:variant_image, :unique_image_file_name => REMOTE_IMAGE)		
		#TODO if no internet connectivity
		vi.stubs(:open_io_uri).returns(vi.open_io_file(LOCAL_IMAGE))
    vi.save
	  assert_equal REMOTE_IMAGE, vi.unique_image_file_name
	  assert vi.valid?		
		assert_equal 300, vi.image_width # we know logo.png is 300x60
		assert_equal 60, vi.image_height
		
		# Confirm primary image was saved
		assert_equal 7447, vi.image_file_size  # we know logo.png is 7kb
		assert_equal 'image/png', vi.image_content_type
		assert_equal IMAGE_FILE_NAME, vi.image_file_name

    # Confirm image was replicated to second server
		assert_equal 7447, vi.image2_file_size
		assert_equal 'image/png', vi.image2_content_type
		assert_equal IMAGE_FILE_NAME, vi.image2_file_name
	end
	
	test "image upload should work for local URL" do
		vi = FactoryGirl.create(:variant_image, :unique_image_file_name => LOCAL_IMAGE)
		assert vi.valid?
		assert_equal LOCAL_IMAGE, vi.unique_image_file_name 		
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
