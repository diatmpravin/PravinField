require 'test_helper'

class MwsOrderTest < ActiveSupport::TestCase

	test "basic mws_order should be valid" do
		o = FactoryGirl.create(:mws_order)
		assert o.valid?
	end

	#validates_uniqueness_of :amazon_order_id
	test "amazon_order_id should be unique" do		
		assert_difference('MwsOrder.count',1) do
			o = FactoryGirl.create(:mws_order)
			MwsOrder.create(o.attributes)
		end
	end
	
	#validates_presence_of :mws_response_id
	test "mws_response_id is required" do
		o = FactoryGirl.create(:mws_order)
		o.mws_response_id = nil
		assert_difference('MwsOrder.count',0) do
			MwsOrder.create(o.attributes)
		end		
	end
	
	test "purchase date should not be nil" do
		o = FactoryGirl.create(:mws_order)
		o.purchase_date = nil
		assert o.invalid?
		o.purchase_date = Time.now
		assert o.valid?
	end
	
	test "get_item_quantity_loaded/ordered/missing should work" do
		o = FactoryGirl.create(:mws_order, :number_of_items_unshipped => 2, :number_of_items_shipped => 1)
		assert_equal 0, o.get_item_quantity_loaded
		assert_equal 3, o.get_item_quantity_ordered
		assert_equal 3, o.get_item_quantity_missing
		
		i = FactoryGirl.create(:mws_order_item, :mws_order => o, :quantity_shipped => 0, :quantity_ordered => 2)
		assert_equal 2, o.reload.get_item_quantity_loaded
		assert_equal 3, o.get_item_quantity_ordered
		assert_equal 1, o.get_item_quantity_missing
		
		i2 = FactoryGirl.create(:mws_order_item, :mws_order => o, :quantity_shipped => 1, :quantity_ordered => 1)
		assert_equal 3, o.reload.get_item_quantity_loaded
		assert_equal 3, o.get_item_quantity_ordered
		assert_equal 0, o.get_item_quantity_missing
	end
	
	test "get_sleep_time_per_order should work" do
		assert_equal 0, MwsOrder::get_sleep_time_per_order("text")
		assert_equal 0, MwsOrder::get_sleep_time_per_order(-1)
		assert_equal 0, MwsOrder::get_sleep_time_per_order(0)
		assert_equal 0, MwsOrder::get_sleep_time_per_order(1)
		assert_equal 0, MwsOrder::get_sleep_time_per_order(15)
		assert MwsOrder::get_sleep_time_per_order(16) > 0
		assert MwsOrder::get_sleep_time_per_order(50.5) > 0
		assert MwsOrder::get_sleep_time_per_order(10000) <= 6
	end
	
	test "order should have an associated MWS connection" do
		s = FactoryGirl.create(:store, :name => 'FieldDay')
		o = FactoryGirl.create(:mws_order, :store => s)
  	#o = MwsOrder.find(o.id)
  	s = o.reload.store
  	assert s.valid?
  	assert_equal 'FieldDay', s.name
  	assert_equal 'MWS', s.store_type		
		assert_instance_of Amazon::MWS::Base, s.mws_connection
	end
	
	test "reprocess_order should work" do
		s = FactoryGirl.create(:store, :name => 'FieldDay')
		o = FactoryGirl.create(:mws_order, :store => s)		
  	#o.reprocess_order
  	#TODO what to assert?  Just needs to not return error?
	end
	
	test "set_shipped should work" do
	  o = FactoryGirl.create(:mws_order)
		i = FactoryGirl.create(:mws_order_item, :mws_order_id=>o.to_param, :quantity_ordered => 2, :quantity_shipped => 0)
		i2 = FactoryGirl.create(:mws_order_item, :mws_order_id=>o.to_param, :quantity_ordered => 2, :quantity_shipped => 0)
		
		assert_equal 0, i.quantity_shipped
		assert_equal 0, i2.quantity_shipped
		o.set_shipped
		assert_equal 2, i.reload.quantity_shipped
		assert_equal 2, i2.reload.quantity_shipped	  
	end
	
	test "get prices should work" do
	  o = FactoryGirl.create(:mws_order)
		i = FactoryGirl.create(:mws_order_item, :mws_order_id=>o.to_param, :quantity_ordered => 2, :quantity_shipped => 0, :item_price=>1, :shipping_price=>2, :gift_price=>3)
		i2 = FactoryGirl.create(:mws_order_item, :mws_order_id=>o.to_param, :quantity_ordered => 2, :quantity_shipped => 0, :item_price=>1, :shipping_price=>2, :gift_price=>3)	  
	  
	  assert_equal 2, o.get_item_price
	  assert_equal 4, o.get_ship_price
	  assert_equal 6, o.get_gift_price
	  assert_equal (o.get_item_price + o.get_ship_price + o.get_gift_price), o.get_total_price
	end
	
	test "omx_responses relation and pushed_to_omx? should work" do
		s = FactoryGirl.create(:store, :name => 'FieldDay')
		o = FactoryGirl.create(:mws_order, :store => s, :order_status => 'Unshipped')
		assert_equal 0, o.omx_responses.count
		assert_equal "Error", o.pushed_to_omx?
		
		i = FactoryGirl.create(:mws_order_item, :mws_order => o)
		req = FactoryGirl.create(:omx_request, :mws_order => o)
		resp = FactoryGirl.create(:omx_response, :omx_request => req)
		assert_equal 1, o.omx_responses.count
		assert_equal "Error", o.pushed_to_omx?
		
		o.append_to_omx
		assert_equal "No", o.reload.pushed_to_omx?

		resp.ordermotion_order_number = 'omx_order_number'
		resp.save
		assert_equal 'Yes', o.reload.pushed_to_omx?
		
		resp.ordermotion_order_number = nil
		resp.error_data = 'The provided Order ID has already been used for the provided store (Amazon.com MFN HDO).'
		resp.save
		assert_equal 'Dup', o.reload.pushed_to_omx?

		o.order_status = 'Shipped'
		o.save
		assert_equal 'Shipped', o.reload.pushed_to_omx?
		
		o.fulfillment_channel = 'AFN'
		o.save
		assert_equal 'N/A', o.reload.pushed_to_omx?
	end
			
	test "omx_first_name should work" do
		o = FactoryGirl.create(:mws_order, :name => 'Bob C. Smith')
		assert_equal 'Bob C.', o.omx_first_name
		
		o.name = 'Smith'
		assert_equal '[Blank]', o.omx_first_name
		
		o.name = nil
		assert_equal '[Blank]', o.omx_first_name		
	end

	test "omx_last_name should work" do
		o = FactoryGirl.create(:mws_order, :name => 'Bob C. Smith')
		assert_equal 'Smith', o.omx_last_name
		
		o.name = 'Smith'
		assert_equal 'Smith', o.omx_last_name
		
		o.name = nil
		assert_equal '[Blank]', o.omx_last_name
	end
	
	test "omx_shipping_method should work" do
		o = FactoryGirl.create(:mws_order)
		assert_equal 9, o.omx_shipping_method
		o.shipment_service_level_category = 'Expedited'
		assert_equal 18, o.omx_shipping_method
		o.shipment_service_level_category = 'NextDay'
		assert_equal 19, o.omx_shipping_method
		o.shipment_service_level_category = 'SecondDay'
		assert_equal 20, o.omx_shipping_method
		o.shipment_service_level_category = 'Blah Blah'
		assert_equal 9, o.omx_shipping_method
	end

	test "omx_state should work" do
		o = FactoryGirl.create(:mws_order)
		s = FactoryGirl.create(:state, :raw_state => 'Pennsylvania', :clean_state => 'PA')
		assert_equal nil, o.omx_state
		o.state_or_region = 'Not In The List'
		assert_equal 'Not In The List', o.omx_state
		o.state_or_region = 'Pennsylvania'
		assert_equal 'PA', o.omx_state
	end

	test "omx_country should work" do
		o = FactoryGirl.create(:mws_order)
		s = FactoryGirl.create(:state, :raw_state => 'GB', :clean_state => 'UK')
		assert_equal nil, o.omx_country
		o.country_code = 'Not In The List'
		assert_equal 'Not In The List', o.omx_country
		o.country_code = 'GB'
		assert_equal 'UK', o.omx_country
	end

	test "omx_gift_wrap etc should work" do
		o = FactoryGirl.create(:mws_order)
		assert_equal nil, o.omx_gift_wrap_level
		assert_equal nil, o.omx_gift_message
		assert_equal 'False', o.omx_gift_wrapping
		
		i = FactoryGirl.create(:mws_order_item, :mws_order => o)
		i2 = FactoryGirl.create(:mws_order_item, :mws_order => o)
		assert_equal 'False', o.reload.omx_gift_wrapping
		
		i2.gift_message_text = 'Happy Birthday'
		i2.save
		assert_equal 'True', o.reload.omx_gift_wrapping
		assert_equal 'Happy Birthday', o.omx_gift_message
		assert_equal nil, o.omx_gift_wrap_level
		
		i2.gift_message_text = nil
		i2.gift_wrap_level = 'Wrapped'
		i2.save

		assert_equal 'True', o.reload.omx_gift_wrapping
		assert_equal nil, o.omx_gift_message
		assert_equal 'Wrapped', o.omx_gift_wrap_level		
	end

	test "search should work" do
		o = FactoryGirl.create(:mws_order, :name => 'Carmichel')
		oi = FactoryGirl.create(:mws_order_item, :mws_order => o, :title => 'Ray-Bans')
		oi2 = FactoryGirl.create(:mws_order_item, :mws_order => o, :title => 'Ray-Bans')
		o2 = FactoryGirl.create(:mws_order, :name => 'Carmichel')
		oi3 = FactoryGirl.create(:mws_order_item, :mws_order => o2, :asin => 'Ray-ABC345')
		o3 = FactoryGirl.create(:mws_order, :name => 'Nonsense')
		
		# search term matching a single order via two items
		arr = MwsOrder.search('Ray-Ban')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal 1, arr.length
		assert_equal o, arr[0]
		
		# search term partially matching 2 orders
		arr = MwsOrder.search('Ray-')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal 2, arr.length
		assert_equal [o,o2], arr

		arr = MwsOrder.search('Carmichel')
		assert_equal 2, arr.length
		
		# search term matching back half of string only matching 1 order
		arr = MwsOrder.search('ABC')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal 1, arr.size
		assert_equal o2, arr[0]
		
		# search term should not match any orders
		arr = MwsOrder.search('xxx')
		assert_instance_of ActiveRecord::Relation, arr
		assert arr.empty?
	
		# no search term should return all 3 orders
		#arr = MwsOrder.search(nil)
		#assert_instance_of ActiveRecord::Relation, arr
		#assert_equal 3, arr.length

	end
				
	#TODO test append_to_omx
	#TODO test process_order
	#TODO test fetch_order_items
	#TODO test process_order_item
end
