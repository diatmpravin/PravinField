# encoding: utf-8
require 'test_helper'
require 'amazon/mws'

class ListingTest < ActiveSupport::TestCase
  
  PARENT_ROWS = 1
  CHILD_ROWS = 4
  IMAGES_PER_CHILD = 2
  STEPS_PER_FEED = 5
  REQUESTS_PER_STEP = 3
  
  def setup
    @b = FactoryGirl.create(:brand, :name=>'Pearl Izumi')
	  @p = FactoryGirl.create(:product, :brand_id=>@b.id, :sku=>'0269', :name=>'Pro Ltd Bib Short', 
	        :description=>'The P.R.O. LTD Bib Short utilizes the anatomic fit, comfort and performance of our race proven team bibs with the addition of original, sublimated Pearl Izumi designs and the Anatomic P.R.O. Seamless 4D Chamois. P.R.O. Transfer fabric provides optimal stretch, recovery, and compression and moisture transfer P.R.O. Aero panels with In-R-Cool technology Direct-Vent panels provide superior ventilation Anatomic multi-panel design Flatlock seams Silicone leg gripper Anatomic P.R.O. Seamless 4D Chamois 9" inseam [size medium]', 
	        :bullet_points=>['4D Seamless Chamois','IN-R-COOL MOISTURE TRANSFER','VENTILATION'].join(Import::KEYWORD_DELIMITER),
	        :search_keywords=>["Men's Cycling Apparel","Cycling Gear","Bib Short",'Cycle'].join(Import::KEYWORD_DELIMITER), 
	        :variation_theme=>'SizeColor',
	        :department=>['Mens'].join(Import::KEYWORD_DELIMITER),
	        :product_type=>'Shorts',
	        :style_keywords=>['Athletic', 'Form Fit', 'Race Proven', 'Anatomic 4D Chamois', 'IN-R-COOL'].join(Import::KEYWORD_DELIMITER),
	        :occasion_lifestyle_keywords=>['Athlete', 'Weekend Warrior', 'Competitor', 'Cycling'].join(Import::KEYWORD_DELIMITER))
	        
	  @v1 = FactoryGirl.create(:variant, :sku=>'0269-3IZ', :color1=>'Prey Black', :color1_code=>'3IZ',
	        :product_id=>@p.id, :msrp=>164.95, :price=>164.95, :sale_price=>164.95)
	  @v2 = FactoryGirl.create(:variant, :sku=>'0269-3JB', :color1=>'Sustain White', :color1_code=>'3JB', 
	        :product_id=>@p.id, :msrp=>164.95, :price=>164.95, :sale_price=>164.95)
	  
	  @sv1 = FactoryGirl.create(:sub_variant, :variant_id=>@v1.id, :sku=>'0269-3IZ-SM', :upc=>'703051803094', 
	        :size=>'Small', :size_code=>'SM', :quantity=>0, :fulfillment_latency=>12)
	  @sv2 = FactoryGirl.create(:sub_variant, :variant_id=>@v1.id, :sku=>'0269-3IZ-MD', :upc=>'703051803100', 
	        :size=>'Medium', :size_code=>'MD', :quantity=>0, :fulfillment_latency=>12)
	  @sv3 = FactoryGirl.create(:sub_variant, :variant_id=>@v2.id, :sku=>'0269-3JB-SM', :upc=>'703051803148', 
	        :size=>'Small', :size_code=>'SM', :quantity=>0, :fulfillment_latency=>12)
	  @sv4 = FactoryGirl.create(:sub_variant, :variant_id=>@v2.id, :sku=>'0269-3JB-MD', :upc=>'703051803155', 
	        :size=>'Medium', :size_code=>'MD', :quantity=>0, :fulfillment_latency=>12)
	  
	  @vi1 = FactoryGirl.create(:variant_image, :variant_id=>@v1.id, :unique_image_file_name=>LOCAL_IMAGE_PATH+'0269_3QW_v1_m56577569830762236.png')
	  @vi2 = FactoryGirl.create(:variant_image, :variant_id=>@v1.id, :unique_image_file_name=>LOCAL_IMAGE_PATH+'0269_3QW_BACK_v1_m56577569830762237.png')
	  @vi3 = FactoryGirl.create(:variant_image, :variant_id=>@v2.id, :unique_image_file_name=>LOCAL_IMAGE_PATH+'0269_3RO_v1_m56577569830762238.png')
	  @vi4 = FactoryGirl.create(:variant_image, :variant_id=>@v2.id, :unique_image_file_name=>LOCAL_IMAGE_PATH+'0269_3RO_BACK_v1_m56577569830762239.png') 
    
    @s = FactoryGirl.create(:store, :store_type=>'MWS')
    @s.mws_connection.stubs(:post).returns(xml_for('submit_feed',200))
    @s.mws_connection.stubs(:get).returns(xml_for('get_feed_submission_list',200))
    @s.mws_connection.stubs(:get_feed_submission_result).returns(GetFeedSubmissionResultResponse.format(xml_for('get_feed_submission_result',200)))
  
	  @r_product = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
	              :feed_type=>MwsRequest::FEED_STEPS[0], :message_type=>'Product')
	  @listing = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', :product_id=>@p.id)     
  end
  
	test "assign_amazon! should work for product data" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)	  
	  assert_difference('MwsMessage.count',PARENT_ROWS+CHILD_ROWS) do
	    a = @listing.assign_amazon!(@r_product)
      assert_kind_of Array, a
      @r_product.update_attributes(:message => a)
      
      assert_difference('MwsResponse.count',1) do
        response = @r_product.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
        request = response.mws_request
        assert_nil request.mws_request_id # should not have a parent
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render
      end
    end
  end
  
  test "assign_amazon! should work for relationship data" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)

    r_relationship = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[1], :message_type=>MwsRequest::FEED_MSGS[1])
 
    # a relationship only has a single message
 	  assert_difference('MwsMessage.count',PARENT_ROWS) do
	    a = @listing.assign_amazon!(r_relationship)
      assert_kind_of Array, a
      r_relationship.message = a
      r_relationship.save
      
      assert_difference('MwsResponse.count',1) do
        response = r_relationship.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render        
      end
    end
  end

  test "assign_amazon! should work for product pricing" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)    
    r_pricing = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[2], :message_type=>MwsRequest::FEED_MSGS[2])
 
 	  assert_difference('MwsMessage.count',CHILD_ROWS) do
	    a = @listing.assign_amazon!(r_pricing)
      assert_kind_of Array, a
      r_pricing.message = a
      r_pricing.save
      
      assert_difference('MwsResponse.count',1) do
        response = r_pricing.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render
      end
    end
  end

  test "assign_amazon! should work for product image data" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)    
    r_image = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[3], :message_type=>MwsRequest::FEED_MSGS[3])
 
 	  assert_difference('MwsMessage.count',CHILD_ROWS*IMAGES_PER_CHILD) do
	    a = @listing.assign_amazon!(r_image)
      assert_kind_of Array, a
      r_image.message = a
      r_image.save
      
      assert_difference('MwsResponse.count',1) do
        response = r_image.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render
      end
    end
  end
  
  test "assign_amazon! should work for inventory availability" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)    
    r_inventory = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[4], :message_type=>MwsRequest::FEED_MSGS[4])
    #@listing = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', 
    #                :product_id=>@p.id, :parent_listing_id=>@listing.id)
 
 	  assert_difference('MwsMessage.count',CHILD_ROWS) do
	    a = @listing.assign_amazon!(r_inventory)
      assert_kind_of Array, a
      r_inventory.update_attributes(:message => a)
      
      assert_difference('MwsResponse.count',1) do
        response = r_inventory.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render        
        #puts response.mws_request.message
      end
    end
  end

  test "update_status! should work" do
    # normal usage, when finished processing listing status turns to active
    assert_equal 'queued', @listing.status
    @listing.update_status!
    assert_equal 'active', @listing.reload.status

    # a newer listing will change older listings to updated
    @listing2 = FactoryGirl.create(:listing, :product_id=>@listing.product_id, :store_id=>@listing.store_id, :operation_type=>'Update')
    @listing2.update_status!
    assert_equal 'active', @listing2.reload.status
    assert_equal 'updated', @listing.reload.status
    
    # if the listing has error messages associated with it, then it will return error
    m = FactoryGirl.create(:mws_message, :listing_id=>@listing.id, :result_code=>'Error')
    @listing.update_status!
    assert_equal 'error', @listing.reload.status
      
    # delete listings will be deleted
	  @l_remove = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Delete', :product_id=>@p.id)     
    @l_remove.update_status!
    assert_equal 'deleted', @l_remove.reload.status
    
    # changes open error listings to aborted
    assert_equal 'aborted', @listing.reload.status
    
    # and existing active listings to removed
    @listing.update_attributes(:status=>'active')
    @l_remove.update_status!
    assert_equal 'removed', @listing.reload.status

    # error messages can pile up (there may be more than one)
    m = FactoryGirl.create(:mws_message, :listing_id=>@listing2.id, :result_code=>'Error')
    @listing2.update_status!
    assert_equal 'error', @listing2.reload.status
    @listing3 = FactoryGirl.create(:listing, :product_id=>@listing.product_id, :store_id=>@listing.store_id, :operation_type=>'Update')
    m = FactoryGirl.create(:mws_message, :listing_id=>@listing3.id, :result_code=>'Error')  
    @listing3.update_status!
    assert_equal 'error', @listing3.reload.status
    assert_equal 'error', @listing2.reload.status

    # error messages that are superseded by newer updates will read "corrected"    
    @listing4 = FactoryGirl.create(:listing, :product_id=>@listing.product_id, :store_id=>@listing.store_id, :operation_type=>'Update')
    @listing4.update_status!
    assert_equal 'active', @listing4.reload.status
    assert_equal 'corrected', @listing3.reload.status
    assert_equal 'corrected', @listing2.reload.status    
  end


  test "sync_listings should work synchronously for MWS" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)
    expected_messages_count = (PARENT_ROWS+CHILD_ROWS)+(PARENT_ROWS)+(CHILD_ROWS)+(CHILD_ROWS*IMAGES_PER_CHILD)+(CHILD_ROWS)
    assert_equal 0, MwsMessage.count
 	  assert_difference('Listing.count',0) do
 	    assert_difference('MwsMessage.count',expected_messages_count) do      
        assert_difference('MwsRequest.count',STEPS_PER_FEED*REQUESTS_PER_STEP) do
          assert_difference('MwsResponse.count',STEPS_PER_FEED*REQUESTS_PER_STEP) do
	          response = @s.sync_listings(false)
	          pr = response.mws_request
	          assert_equal 'SubmitFeed', pr.request_type
	          assert_nil pr.mws_request_id # should be no parent
	          
	          assert_equal MwsRequest::FEED_STEPS[0], pr.feed_type
	          assert_equal STEPS_PER_FEED-1 + REQUESTS_PER_STEP-1, pr.sub_requests.count
	          assert_equal 1, pr.listings.count
	          assert_equal @listing, pr.listings[0]
	          assert_equal expected_messages_count, pr.listings[0].mws_messages.count
	          assert_equal 'active', pr.listings[0].reload.status
          end
        end
      end
    end

		# confirm listing was created
		assert_equal 1, @s.reload.products.count
		assert_equal 1, @p.reload.stores.count
		assert_equal @p, @s.products.first
		assert_equal @s, @p.stores.first

    # remove product from store
	  @l_remove = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Delete', :product_id=>@p.id) 
    assert_equal 1, @s.reload.queued_listings.count
    assert_equal 1, @p.reload.queued_listings.count
    
    expected_messages_count = (PARENT_ROWS+CHILD_ROWS)
 	  assert_difference('Listing.count',0) do
 	    assert_difference('MwsMessage.count',expected_messages_count) do      
        assert_difference('MwsRequest.count',1*REQUESTS_PER_STEP) do
          assert_difference('MwsResponse.count',1*REQUESTS_PER_STEP) do
	          response = @s.sync_listings(false)
	          pr = response.mws_request
	          assert_equal 'SubmitFeed', pr.request_type
	          assert_equal MwsRequest::FEED_STEPS[0], pr.feed_type
	          assert_equal REQUESTS_PER_STEP-1, pr.sub_requests.count
	          assert_equal 1, pr.listings.count
	          assert_equal @l_remove, pr.listings[0]
	          assert_equal expected_messages_count, pr.listings[0].mws_messages.count
	          assert_equal 'deleted', pr.listings[0].reload.status
	          assert_equal 'removed', @listing.reload.status
          end
        end
      end
    end

    # Store has 2 listings, but no active listings
    assert_equal 2, @s.reload.listings.count
		assert_equal 0, @s.products.count
		assert_equal 0, @s.queued_listings.count
		
    # Product has 2 listings, but no active listings
    assert_equal 2, @p.reload.listings.count
		assert_equal 0, @p.stores.count
		assert_equal 0, @p.queued_listings.count
  end
  
  test "update and delete listing in same batch should work for MWS" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)    
    # this way, a newer delete will override an older update, and vice versa
    @l_remove = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Delete', :product_id=>@p.id, :status=>'queued') 
	  assert_equal @listing, @s.queued_listings.first
	  assert_equal @l_remove, @s.queued_listings.last
	  response = @s.sync_listings(false)
	  
    # Store has 2 listings, but no active listings
    assert_equal 2, @s.reload.listings.count
		assert_equal 0, @s.products.count
		
    # Product has 2 listings, but no active listings
    assert_equal 2, @p.reload.listings.count
		assert_equal 0, @p.stores.count
  end
  
  test "sync_listings should work asynchronously for MWS" do
    MwsMessage.stubs(:find).returns(MwsMessage.new)    
   	assert_difference('Listing.count',0) do
   	  assert_difference('MwsMessage.count',STEPS_PER_FEED) do      
        assert_difference('MwsRequest.count',1) do
          assert_difference('MwsResponse.count',0) do
  	        response = @s.sync_listings
  	        assert_kind_of Delayed::Backend::ActiveRecord::Job, response
          end
        end
      end
    end
  end    

  test "get dirty products should work" do
    pending 
  end

=begin
  test "sync_listings should work LIVE for MWS" do
    @s2 = FactoryGirl.create(:store, :store_type=>'MWS', :name=>'FieldDay')
	  @listing = FactoryGirl.create(:listing, :store_id=>@s2.id, :operation_type=>'Update', :product_id=>@p.id)
    assert_equal @listing, @s2.queued_listings.first
    response = @s2.sync_listings(false)
    assert_equal 0, @s2.queued_listings.count
    puts response.inspect
    puts response.error_message.inspect
    pr = response.mws_request
    puts pr.inspect
    assert_equal 'SubmitFeed', pr.request_type
    assert_equal MwsRequest::FEED_STEPS[0], pr.feed_type
    assert_equal 1, pr.listings.count
    assert_equal @listing, pr.listings[0]
    assert_equal expected_messages_count, pr.listings[0].mws_messages.count
    assert_equal 'active', pr.listings[0].reload.status
    
    @listing2 = FactoryGirl.create(:listing, :store_id=>@s2.id, :operation_type=>'Delete', :product_id=>@p.id)
    response = @s2.sync_listings(false)
  end
=end

end