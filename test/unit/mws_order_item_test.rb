require 'test_helper'

class MwsOrderItemTest < ActiveSupport::TestCase

	test "amazon_order_item_id should be unique" do
		o = FactoryGirl.create(:mws_order)
		i = FactoryGirl.create(:mws_order_item, :mws_order => o)
		i2 = FactoryGirl.build(:mws_order_item, :mws_order => o)
		i2.amazon_order_item_id = i.amazon_order_item_id
		assert i2.invalid?
	end
	
	test "should save clean_sku" do
		i = FactoryGirl.create(:mws_order_item)
		assert_not_nil i.clean_sku
	end

	test "set_shipped should work" do
		i = FactoryGirl.create(:mws_order_item, :quantity_ordered => 2, :quantity_shipped => 0)
		assert_equal 0, i.quantity_shipped
		i.set_shipped
		assert_equal 2, i.quantity_shipped
	end

	test "is_gift should work" do
		i = FactoryGirl.create(:mws_order_item)
		assert_equal 0, i.is_gift?
		i.gift_message_text = "Testing"
		assert_equal 1, i.is_gift?
		i.gift_message_text = nil
		assert_equal 0, i.is_gift?
		i.gift_wrap_level = "Testing"
		assert_equal 1, i.is_gift?
	end

	test "get_item_price_per_unit should work" do
		price = 150.0
		i = FactoryGirl.create(:mws_order_item)
		assert_equal 0, i.get_item_price_per_unit
		i.quantity_ordered = 0
		assert_equal 0, i.get_item_price_per_unit
		assert_equal i.get_item_price, i.get_item_price_per_unit
		i.quantity_ordered = 1.0
		i.item_price = price
		assert_equal i.get_item_price, i.get_item_price_per_unit
		i.quantity_ordered = 2.0
		i.item_price = i.quantity_ordered*price
		i.item_tax = 20.0
		i.promotion_discount = 5.0
		assert_equal ((i.quantity_ordered*price + i.item_tax - i.promotion_discount)/ i.quantity_ordered), i.get_item_price_per_unit
	end
	
	test "get_item_prices etc should work" do
		o = FactoryGirl.create(:mws_order)
		i = FactoryGirl.create(:mws_order_item, :mws_order => o)
		assert_equal 0, i.get_item_price
		assert_equal 0, i.get_ship_price
		assert_equal 0, i.get_gift_price
		assert_equal 0, i.get_total_price
		assert_equal 0, i.get_price_subtotal
		assert_equal 0, i.get_discount_subtotal
		assert_equal 0, i.get_tax_subtotal

		i2 = FactoryGirl.create(:mws_order_item, :mws_order => o, :quantity_ordered => 2, :item_price => 300, :item_tax => 20, :promotion_discount => 5, :shipping_price => 19, :shipping_tax => 5, :shipping_discount => 3, :gift_price => 7, :gift_tax => 1.5)
		assert_equal 315, i2.get_item_price
		assert_equal (19+5-3), i2.get_ship_price
		assert_equal (7+1.5), i2.get_gift_price
		assert_equal (315 + 19 + 5 -3 + 7 + 1.5), i2.get_total_price
		assert_equal i2.get_item_price + i2.get_ship_price + i2.get_gift_price, i2.get_total_price
		assert_equal (300 + 19 + 7), i2.get_price_subtotal
		assert_equal (5 + 3), i2.get_discount_subtotal
		assert_equal (20 + 5 + 1.5), i2.get_tax_subtotal		
	end

	test "numbers should be positive and valid" do
		i = FactoryGirl.create(:mws_order_item)
		i.item_price = -26.5
		assert i.invalid?
		i.item_price = "nan"
		assert i.invalid?
		i.item_price = 0
		assert i.valid?
		
		assert_equal 0,i.quantity_ordered
		i.quantity_ordered = 1.5
		assert i.invalid?
		i.quantity_ordered = 2
		assert i.valid?
	end
	
	test "search should work" do
		o = FactoryGirl.create(:mws_order)
		oi = FactoryGirl.create(:mws_order_item, :mws_order => o, :title => 'Ray-Bans')
		oi2 = FactoryGirl.create(:mws_order_item, :mws_order => o, :title => 'Ray-Bans')
		o2 = FactoryGirl.create(:mws_order)
		oi3 = FactoryGirl.create(:mws_order_item, :mws_order => o2, :asin => 'Ray-ABC345')
		o3 = FactoryGirl.create(:mws_order)

		# search term partially matching 2 orders
		arr = MwsOrderItem.search('Ray-')
		assert_equal 2, arr.length
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal oi.mws_order_id, arr[0].mws_order_id
		assert_equal oi3.mws_order_id, arr[1].mws_order_id
		
		# search term matching a single order via two items
		arr = MwsOrderItem.search('Ray-Ban')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal oi.mws_order_id, arr[0].mws_order_id
		assert_equal 1, arr.length
		
		# search term matching back half of string only matching 1 order
		arr = MwsOrderItem.search('ABC')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal oi3.mws_order_id, arr[0].mws_order_id
		assert_equal 1, arr.length
		
		# no search term should return all 3 orders
		#arr = MwsOrderItem.search(nil)
		#assert_instance_of ActiveRecord::Relation, arr
		#assert_equal o.id, arr[0].mws_order_id
		#assert_equal 3, arr.length

		# search term should not match any orders
		arr = MwsOrderItem.search('xxx')
		assert_instance_of ActiveRecord::Relation, arr
		assert arr.empty?
	end

	test "get_catalog_match should work" do	
		p = FactoryGirl.create(:product)
		oi = FactoryGirl.create(:mws_order_item, :seller_sku=>p.sku)
		assert_equal p, oi.product
		
		v = FactoryGirl.create(:variant, :product=>p, :sku=>p.sku+'apple')
		oi2 = FactoryGirl.create(:mws_order_item,:seller_sku=>v.sku)
		assert_equal p, oi2.product
		assert_equal v, oi2.variant
		
		sv = FactoryGirl.create(:sub_variant, :variant=>v, :sku=>v.sku+'orange')
		oi3 = FactoryGirl.create(:mws_order_item, :seller_sku=>sv.sku)
		assert_equal sv, oi3.sub_variant
		assert_equal v, oi3.variant
		assert_equal p, oi3.product
		
		oi4 = FactoryGirl.create(:mws_order_item, :seller_sku=>'unique_seller_sku')
		assert_nil oi4.product
		assert_nil oi4.variant
		assert_nil oi4.sub_variant
		
		# changing sku should change the parent stuff
		oi4.seller_sku = sv.sku
		oi4.save
		assert_equal sv, oi4.sub_variant
		assert_equal v, oi4.variant
		assert_equal p, oi4.product
	end
		
end
