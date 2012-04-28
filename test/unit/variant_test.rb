require 'test_helper'

class VariantTest < ActiveSupport::TestCase

	test "sku should be unique" do
		p = FactoryGirl.create(:product)
		v = FactoryGirl.create(:variant, :product => p)
		v2 = FactoryGirl.create(:variant, :product => p)
		assert v2.valid?
		v2.sku = v.sku
		assert v2.invalid?
	end
	
	test "should be one master" do
		p = FactoryGirl.create(:product)
		v = FactoryGirl.create(:variant, :product => p)
		assert_equal true, v.is_master
		assert_equal v, p.reload.master
		
		v2 = FactoryGirl.create(:variant, :product => p)
		
		# First ID inserted should be the default master
		assert_equal v.id, p.reload.master.id
		assert_equal true, v.is_master
		assert_equal false, v2.is_master
		
		# adding another variant should not change that
		v3 = FactoryGirl.create(:variant, :product => p)
		assert_equal false, v3.is_master
		
		# destroying the master variant should assign the next as master
		assert_difference 'Variant.count', -1 do
			v.destroy
		end
		assert_equal true, v2.reload.is_master
		v3.reload.set_as_master
		assert_equal false, v2.reload.is_master
		assert_equal true, v3.reload.is_master
		v2.set_as_master
		assert_equal true, v2.reload.is_master
		assert_equal false, v3.reload.is_master		
		v3.set_as_master
		assert_equal false, v2.reload.is_master
		assert_equal true, v3.reload.is_master		
		v3.destroy
		assert_equal true, v2.reload.is_master
	end
	
	test "mws_order_items association should work" do
		v = FactoryGirl.create(:variant, :sku => 'ABCDEFG')
		assert_equal 0, v.mws_order_items.count
		
		o = FactoryGirl.create(:mws_order)
		i = FactoryGirl.create(:mws_order_item, :mws_order => o, :seller_sku => 'ABCDEFG')
		assert_equal 1, v.mws_order_items.count
		i2 = FactoryGirl.create(:mws_order_item, :mws_order => o, :seller_sku => 'ABCDEFG')
		assert_equal 2, v.mws_order_items.count
	end

	test "get_style should work" do
		v = FactoryGirl.create(:variant)
		assert_equal '', v.get_style
		v.color1 = 'Green '
		v.save
		assert_equal 'Green', v.reload.get_style
		v.color2 = ' Blue'
		v.save
		assert_equal 'Green Blue', v.reload.get_style
	end
	
	test "get_attributes_for_shopify should work" do
		p = FactoryGirl.create(:product, :name => 'Aviators')
		v = FactoryGirl.create(:variant, :product => p, :color1 => 'Green', :color2 => 'Blue', :cost_price => 1)
		a = v.get_attributes_for_shopify
		assert_equal 'Aviators (Green Blue)', a[:title]
		assert_equal 'Green Blue', a[:option1]
		assert_equal v.sku, a[:sku]
		assert_equal 2, a[:price] # default markup of 100%
	end
	
	test "get_image_for_shopify(i) should work" do
		v = FactoryGirl.create(:variant)
		assert_equal nil, v.get_image_for_shopify(nil)
		assert_equal nil, v.get_image_for_shopify(0)
		vi = FactoryGirl.create(:variant_image, :variant => v, :image_file_name => 'blah', :image_width => 400)
		temp1 = { :src => vi.image.url }
		assert_equal temp1, v.reload.get_image_for_shopify(0)
		vi2 = FactoryGirl.create(:variant_image, :variant => v, :image_file_name => 'blah2', :image_width => 320)
		temp2 = { :src => vi2.image.url }
		assert_equal temp1, v.reload.get_image_for_shopify(0)
		assert_equal temp2, v.reload.get_image_for_shopify(1)
	end

	test "search should work" do
		p = FactoryGirl.create(:product)
		v = FactoryGirl.create(:variant, :product_id => p.id, :sku => 'Ray-Bans')
		v2 = FactoryGirl.create(:variant, :product_id => p.id, :sku => 'Ray-Bans2')
		p2 = FactoryGirl.create(:product)
		v3 = FactoryGirl.create(:variant, :product_id => p2.id, :sku => 'Ray-ABC345')
		p3 = FactoryGirl.create(:product)

		# search term partially matching 2 products
		arr = Variant.search('Ray-')
		assert_equal 2, arr.length
		assert arr.include?(v.product_id)
		assert arr.include?(v3.product_id)
		
		# search term matching a product via two variants
		arr = Variant.search('Ray-Ban')
		assert_equal 1, arr.length
		assert_equal v.product_id, arr[0]
		
		# search term matching back half of string only matching 1 product
		arr = Variant.search('ABC')
		assert_equal 1, arr.length
		assert_equal v3.product_id, arr[0]
		
		# search term should not match any products
		arr = Variant.search('xxx')
		assert arr.empty?
	end
	
end
