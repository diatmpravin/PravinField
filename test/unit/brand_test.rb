require 'test_helper'

class BrandTest < ActiveSupport::TestCase

	test "name should be unique" do
		b = FactoryGirl.create(:brand)
		assert_difference('Brand.count',0) do
			Brand.create(b.attributes)
		end	

		b.name = 'unique brand name'
		assert_difference('Brand.count',1) do
			Brand.create(b.attributes)
		end
	end
   
	test "default_markup should be a number greater than zero" do   	
		b = FactoryGirl.create(:brand)
		b.default_markup = "NAN"
		assert b.invalid?
		assert b.errors[:default_markup].any?
		b.default_markup = 0.75
		assert b.valid?
		b.default_markup = 3
		assert b.valid?
		b.default_markup = -0.5
		assert b.invalid?
		assert b.errors[:default_markup].any?
		b.default_markup = 0
		assert b.invalid?
		assert b.errors[:default_markup].any?
	end
	
	#test "process_from_vendor should work" do
		#TODO what to test here?
	#end

	test "has a vendor" do
		b = FactoryGirl.create(:brand)
		assert_instance_of Vendor, b.vendor, 'Brand does not have a valid parent vendor'
	end

	test "add_listings should work" do
		b = FactoryGirl.create(:brand)
		p = FactoryGirl.create(:product, :brand => b)
		p2 = FactoryGirl.create(:product, :brand => b)
		s = FactoryGirl.create(:store, :store_type => 'Shopify')
		assert_difference('Listing.count',2) do 
			b.add_listings(s)
		end
		assert_equal 1, p.stores.count
		assert_equal 1, p2.stores.count
		assert_equal 2, s.products.count
		assert_difference('Listing.count',-2) do 
			b.remove_listings(s)
		end
		assert_equal 0, p.reload.stores.count
		assert_equal 0, p2.reload.stores.count
		assert_equal 0, s.reload.products.count				
	end

end
