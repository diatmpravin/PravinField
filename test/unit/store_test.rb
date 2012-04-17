require 'test_helper'

class StoreTest < ActiveSupport::TestCase
    
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

	# shopify stores should have an authenticated URL
	test "shopify stores should have an authenticated URL" do
		s = FactoryGirl.create(:store)
		s.store_type = 'Shopify'
		assert s.valid?
		s.authenticated_url = nil
		assert s.invalid?, "Shopify store with nil authenticated_url is valid"
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

	test "init_mws_connection should work" do
  	s = FactoryGirl.create(:store, :store_type=>'MWS')
		assert_instance_of Amazon::MWS::Base, s.mws_connection
		#s.mws_connection.stubs(:get).returns(xml_for('error',401))
	end

  setup do
    @p = FactoryGirl.create(:product)
		assert_equal 0, @p.stores.count

  end

	test "add and remove listings should work for Shopify" do
    # add shopify store
		s = FactoryGirl.create(:store, :store_type => 'Shopify')		
		assert_equal 0, s.products.count
		
		# add product
		p = FactoryGirl.create(:product)
		
		# add listing to store
		s.add_listings([p])
		#ps = ProductsStore.new(:product_id => p.to_param, :store_id => s.to_param)		
		# Not stubbing connection to Shopify right now as connection is to test store
		#ps.stubs(:append_to_shopify).returns('TEST_FOREIGN_ID')
		#ps.save
		
    # confirm successful addition to store
		assert_equal 1, s.reload.products.count
		assert_equal 1, p.reload.stores.count
		assert_equal p, s.products.first
		assert_equal s, p.stores.first

    # remove from store
		s.remove_listings([p])
		assert_equal 0, s.reload.products.count
		assert_equal 0, p.reload.stores.count
	end

  test "only active listings should be returned" do
    s = FactoryGirl.create(:store, :store_type => 'Shopify')
    p = FactoryGirl.create(:product)
    l = FactoryGirl.create(:listing, :product_id=>p.to_param, :store_id=>s.to_param, :active=>true)
    assert_equal 1, s.reload.listings.count
    assert_equal 1, s.products.count
    
    l.inactivate
    #l.destroy
    assert_equal 0, s.reload.listings.count
    assert_equal 0, s.reload.products.count
  end

  test "add_listings should work for mws" do
		s = FactoryGirl.create(:store, :store_type => 'MWS')		
		assert_equal 0, s.products.count

		# add product
		p = FactoryGirl.create(:product)
		
		# stub mws_connection
		s.mws_connection.stubs(:submit_feed).returns(xml_for('submit_feed',200))
  	s.connection.stubs(:post).returns(xml_for('submit_feed',200)) 
				
		# add listing to store
		s.add_listings([p])
		#ps = ProductsStore.create(:product_id => p.to_param, :store_id => s.to_param)
		
		# confirm product was received
		#assert_equal 1, s.reload.products.count
		#assert_equal 1, p.reload.stores.count
		#assert_equal p, s.products.first
		#assert_equal s, p.stores.first

    # remove product from store
		#ps.destroy
		#assert_equal 0, s.reload.products.count
		#assert_equal 0, p.reload.stores.count		
    
  end
		
end
