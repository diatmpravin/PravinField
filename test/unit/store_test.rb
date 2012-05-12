require 'test_helper'

class StoreTest < ActiveSupport::TestCase

  setup do
    @p = FactoryGirl.create(:product)
  end
    
  test "store_type should be valid" do
		s = FactoryGirl.create(:store)
		
		# valid name, invalid store type
		assert_difference('Store.count',0) do
			s.name = 'Unique store name'
			s.store_type = 'Shopify2'
			Store.create(s.attributes)
		end
  end
  
  test "mws store should have valid connection and page size properties" do
  	s = FactoryGirl.create(:store, :store_type=>'MWS')		
		s.name = 'Unique store name'
		
		# bad order results per page and max order pages
		s2 = Store.new(s.attributes)
		s2.order_results_per_page = nil
		s2.max_order_pages = nil
		assert s2.invalid?
		assert s2.errors['order_results_per_page'].any?
		assert s2.errors['max_order_pages'].any?		
		
		# Verify and Queue flags should default to safe test settings
		assert_equal 'True', s.verify_flag
		assert_equal 'False', s.queue_flag		
	end
  
  test "store name should be unique" do 	
		s = FactoryGirl.create(:store)
			
		# duplicate name	
		assert_difference('Store.count',0) do
			Store.create(s.attributes)
		end
		
		# duplicate name but in new, valid store type context
		assert_difference('Store.count',1) do
			s.store_type = 'Shopify'
			Store.create(s.attributes)
		end
		
		# new and unique name
		assert_difference('Store.count',1) do
			s.name = "unique store name"
			Store.create(s.attributes)
		end
		
	end

  test "add and remove listings should work" do
    @s = FactoryGirl.create(:store, :store_type=>'Shopify')
    @p2 = FactoryGirl.create(:product)
    @s.add_listings([@p, @p2])
    
    assert_equal 0, @s.reload.products.count
    assert_equal 0, @p.reload.stores.count
    assert_equal 2, @s.queued_listings.count
    
    @s.sync_listings(false)
    assert_equal 2, @s.reload.products.count
    assert_equal 1, @p.reload.stores.count
    assert_equal 1, @p2.reload.stores.count
    
    @s.remove_listings([@p])
    assert_equal 2, @s.reload.products.count
    assert_equal 1, @p.reload.stores.count
    assert_equal 1, @s.queued_listings.count
    
    @s.sync_listings(false)
    assert_equal 1, @s.reload.products.count
    assert_equal 0, @p.reload.stores.count
    assert_equal 1, @p2.reload.stores.count
    
    @s.remove_listings([@p2])
    @s.sync_listings(false)
    assert_equal 0, @s.reload.products.count
  end

  test "get_last_date should work" do
    s = FactoryGirl.create(:store)
    d = s.get_last_date # x hours back
    assert_kind_of Time, d
    assert_equal -1, d <=> s.get_last_date # Time.now progresses, so they cannot be equal
    
    # if there is an order, the date should be set on that order
    d = Time.parse('2012-04-19 15:49:16 +0200')
    o = FactoryGirl.create(:mws_order, :last_update_date=>d, :store_id=>s.to_param)
    assert (d - o.last_update_date) < 1 #TODO why is this 1 second off in postgres?
    assert (d - s.reload.get_last_date) < 1
    
    # new order added but with an older last update date
    o2 = FactoryGirl.create(:mws_order, :last_update_date=>(d-1.hours), :store_id=>s.to_param)
    assert (d - s.reload.get_last_date) < 1
  end

  test "fetch_recent_orders should work" do
    s = FactoryGirl.create(:store)
    c = s.mws_connection
    
    c.stubs(:post).returns(xml_for('request_orders',200))
		orders_response = c.get_orders_list(
			:last_updated_after => Time.now.iso8601,
			:results_per_page => 100,
      :fulfillment_channel => ["MFN","AFN"],
			:order_status => ["Unshipped", "PartiallyShipped", "Shipped", "Unfulfillable"],
			:marketplace_id => ['ATVPDKIKX0DER']
		)
		assert_kind_of RequestOrdersResponse, orders_response    
    c.stubs(:get_orders_list).returns(orders_response)

  	c.stubs(:post).returns(xml_for('request_order_items',200))  
		items_response = c.get_list_order_items(:amazon_order_id => '134-562342326-223434325')
		assert_kind_of RequestOrderItemsResponse, items_response
		c.stubs(:get_list_order_items).returns(items_response)
		
  	c.stubs(:post).returns(xml_for('request_order_items_by_next_token',200))  
		items_response2 = c.get_list_order_items_by_next_token(:next_token => '2YgYW55IGNhcm99999999Vhc3VyZS4=')
		assert_kind_of RequestOrderItemsByNextTokenResponse, items_response2
		c.stubs(:get_list_order_items_by_next_token).returns(items_response2)		
    
  	c.stubs(:post).returns(xml_for('request_orders_by_next_token',200))
		orders_response2 = c.get_orders_list_by_next_token(:next_token => '2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=')
		assert_kind_of RequestOrdersByNextTokenResponse, orders_response2
		c.stubs(:get_orders_list_by_next_token).returns(orders_response2)		
        
    assert_difference('MwsOrder.count', 2) do
      assert_difference('MwsOrderItem.count', 2) do #TODO should be 2??
        x = s.fetch_recent_orders
      end
    end
  end
	
	test "get_orders_missing_items should work" do
		assert_difference('MwsOrder.count',1) do
			o = FactoryGirl.create(:mws_order)
			s = o.store
			assert_equal 1, s.get_orders_missing_items.count
		end

		assert_difference('MwsOrder.count',2) do
			o = FactoryGirl.create(:mws_order)
			s = o.store
			o2 = FactoryGirl.create(:mws_order, :store => s)
			assert_equal s, o2.store 
			assert_equal 2, s.get_orders_missing_items.count
		end
	end

	test "init_store_connection should work for MWS" do
  	s = FactoryGirl.create(:store, :store_type=>'MWS')
		assert_instance_of Amazon::MWS::Base, s.mws_connection
	end
	
	test "init_store_connection should work for Shopify" do
		s = FactoryGirl.create(:store, :store_type => 'Shopify') # authenticated URL of test store is in Factory
		assert s.valid?
		s.authenticated_url = nil
		assert s.invalid?, "Shopify store with nil authenticated_url is valid"	  
    assert s.errors[:authenticated_url].any?
	end

  # tests for listings

	test "add and remove listings should work for Shopify" do
    # add shopify store
		s = FactoryGirl.create(:store, :store_type => 'Shopify')		
		assert_equal 0, s.products.count
		
		# add product
		p = FactoryGirl.create(:product)
		
		# add listing to store.  Not stubbing connection to Shopify right now as connection is to test store
		s.add_listings([p])
		
		# No listings yet as we haven't run sync_listings
		assert_equal 0, s.reload.products.count
		assert_equal 0, p.reload.stores.count
		
		# Sync listings synchronously
		s.sync_listings(false)
		
    # Confirm successful addition to store
		assert_equal 1, s.reload.products.count
		assert_equal 1, p.reload.stores.count
		assert_equal p, s.products.first
		assert_equal s, p.stores.first

    # remove from store
		s.remove_listings([p])
		
		# Still have listings as we haven't run sync_listings yet
		assert_equal 1, s.reload.products.count
		assert_equal 1, p.reload.stores.count		
		
		s.sync_listings(false)
		
		# Confirm successful removal from store
		assert_equal 0, s.reload.products.count
		assert_equal 0, p.reload.stores.count
	end
		
	test "get dirty products should work" do
	  s = FactoryGirl.create(:store)
	  
	  p1 = FactoryGirl.create(:product)
	  p2 = FactoryGirl.create(:product)
	  p3 = FactoryGirl.create(:product)
	  p4 = FactoryGirl.create(:product)
	  
	  # store has 2 active listings, 1 queued, and two errors (both on the same product)
	  # cannot set status in create because status is initialized to queued by model
	  l1 = FactoryGirl.create(:listing, :store_id=>s.id, :product_id=>p1.id, :built_at=>Time.now)
	  l1.update_attributes(:status=>'active')
	  l2 = FactoryGirl.create(:listing, :store_id=>s.id, :product_id=>p2.id, :built_at=>Time.now)
	  l2.update_attributes(:status=>'active')
	  
	  # One fresh queued listing
	  l3 = FactoryGirl.create(:listing, :store_id=>s.id, :product_id=>p3.id, :built_at=>nil)
	  
	  # and 2 error listings (both for the same product)
	  l4 = FactoryGirl.create(:listing, :store_id=>s.id, :product_id=>p4.id, :built_at=>Time.now)
	  l4.update_attributes(:status=>'error')
    l5 = FactoryGirl.create(:listing, :store_id=>s.id, :product_id=>p4.id, :built_at=>Time.now)
    l5.update_attributes(:status=>'error')
    
    # Finally, one last listing, a queued listing for an already active product
    l6 = FactoryGirl.create(:listing, :store_id=>s.id, :product_id=>p1.id)

	  assert_equal 2, Listing.where(:status=>'active').count
	  assert_equal 2, s.active_listings.length
	  assert_equal 2, s.products.length
	  assert_equal 2, s.queued_listings.length
	  assert_equal 2, s.queued_products.length
	  assert_equal 1, s.error_products.length
	  assert_equal 2, s.error_listings.length
    assert_equal 0, s.get_dirty_products.length

    # first products does not become dirty because an update is already queued
	  p1.update_attributes(:department=>'MENS')
	  assert p1.reload.get_updated_at > l1.built_at
	  assert l1.reload.is_dirty?
    assert_equal 0, s.reload.get_dirty_products.length	   

    # second product becomes dirty once modified after built_at
	  p2.update_attributes(:department=>'MENS')
	  assert p2.reload.get_updated_at > l2.built_at
	  assert l2.reload.is_dirty?
	  assert_equal 1, s.reload.get_dirty_products.length
	  
	  # a fresh queued product is already queued, so it can't become dirty
	  p3.update_attributes(:department=>'MENS')
	  assert !l3.reload.is_dirty?
	  assert_equal 1, s.reload.get_dirty_products.length
	  
	  # an error product can become dirty and it stays in both lists
	  p4.update_attributes(:department=>'MENS')
	  assert_equal 2, s.reload.get_dirty_products.length
	  assert_equal 1, s.error_products.length

    # queuing the dirty products should remove them from the list of dirty products
    assert_difference("Listing.count",2) do
      s.queue_products
    end
    assert_equal 0, s.reload.get_dirty_products.length
    
    # syncing the queued listings should remove them from the queue
    assert_equal 4, s.queued_listings.length
    assert_equal 4, s.queued_products.length
    s.sync_listings
    assert_equal 0, s.reload.queued_products.length
    assert_equal 'active', l2.reload.status # stays active until the end of processing
	end

end
