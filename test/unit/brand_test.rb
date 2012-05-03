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

  test "revise_variant_skus should work" do
    b = FactoryGirl.create(:brand, :name=>'Polo')
    sp = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}")
    p = FactoryGirl.create(:product, :brand_id=>b.to_param, :sku=>'polo_base')
    v = FactoryGirl.create(:variant, :product_id=>p.to_param, :sku=>'nonsense', :color1_code=>'XX')
    b.revise_variant_skus
    assert_equal 'POLO_BASE-XX', v.reload.sku
  end

	test "add_listings should work" do
    pending "will revisit once we can successfully create a single listing for a product"
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
