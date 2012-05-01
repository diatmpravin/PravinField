require 'test_helper'
require 'amazon/mws'

class ListingTest < ActiveSupport::TestCase
  
  PARENT_ROWS = 1
  CHILD_ROWS = 4
  IMAGES_PER_CHILD = 2
  STEPS_PER_FEED = 5
  REQUESTS_PER_STEP = 3
  
  def setup
	  @p = FactoryGirl.create(:product, :search_keywords=>"term1\rterm2\rterm3")
	  @v1 = FactoryGirl.create(:variant, :product_id=>@p.id, :msrp=>10.00, :price=>10.00, :sale_price=>9.00)
	  @v2 = FactoryGirl.create(:variant, :product_id=>@p.id, :msrp=>10.00, :price=>10.00, :sale_price=>9.00)
	  @sv1 = FactoryGirl.create(:sub_variant, :variant_id=>@v1.id, :upc=>'23432343432')
	  @sv2 = FactoryGirl.create(:sub_variant, :variant_id=>@v1.id, :upc=>'23432343433')
	  @sv3 = FactoryGirl.create(:sub_variant, :variant_id=>@v2.id, :upc=>'23432343434')
	  @sv4 = FactoryGirl.create(:sub_variant, :variant_id=>@v2.id, :upc=>'23432343435')
	  @vi1 = FactoryGirl.create(:variant_image, :variant_id=>@v1.id)
	  @vi2 = FactoryGirl.create(:variant_image, :variant_id=>@v1.id, :unique_image_file_name=>LOCAL_IMAGE2)
	  @vi3 = FactoryGirl.create(:variant_image, :variant_id=>@v2.id, :unique_image_file_name=>LOCAL_IMAGE3)
	  @vi4 = FactoryGirl.create(:variant_image, :variant_id=>@v2.id, :unique_image_file_name=>LOCAL_IMAGE4) 
    @s = FactoryGirl.create(:store, :store_type=>'MWS')
    @s.mws_connection.stubs(:post).returns(xml_for('submit_feed',200))
    @s.mws_connection.stubs(:get).returns(xml_for('get_feed_submission_list',200))
    @s.mws_connection.stubs(:get_feed_submission_result).returns(GetFeedSubmissionResultResponse.format(xml_for('get_feed_submission_result',200)))
    MwsMessage.stubs(:find).returns(MwsMessage.new)
  
	  @r_product = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
	              :feed_type=>MwsRequest::FEED_STEPS[0], :message_type=>'Product')
	  @l_product = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', :product_id=>@p.id)     
  end
  
	test "build_mws_messages should work for product data" do
	  assert_difference('MwsMessage.count',PARENT_ROWS+CHILD_ROWS) do
	    a = @l_product.build_mws_messages(@r_product)
      assert_kind_of Array, a
      @r_product.update_attributes(:message => a)
      
      assert_difference('MwsResponse.count',1) do
        response = @r_product.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
      end
    end
  end
  
  test "build_mws_messages should work for relationship data" do
    # this relationship listing should be created automatically
    r_relationship = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[1], :message_type=>MwsRequest::FEED_MSGS[1])
    l_relationship = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', 
                    :product_id=>@p.id, :parent_listing_id=>@l_product.id)
 
    # a relationship only has a single message
 	  assert_difference('MwsMessage.count',PARENT_ROWS) do
	    a = l_relationship.build_mws_messages(r_relationship)
      assert_kind_of Array, a
      r_relationship.message = a
      r_relationship.save
      
      assert_difference('MwsResponse.count',1) do
        response = r_relationship.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
      end
    end
  end

  test "build_mws_messages should work for product pricing" do
    r_pricing = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[2], :message_type=>MwsRequest::FEED_MSGS[2])
    l_pricing = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', 
                    :product_id=>@p.id, :parent_listing_id=>@l_product.id)
 
 	  assert_difference('MwsMessage.count',CHILD_ROWS) do
	    a = l_pricing.build_mws_messages(r_pricing)
      assert_kind_of Array, a
      r_pricing.message = a
      r_pricing.save
      
      assert_difference('MwsResponse.count',1) do
        response = r_pricing.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
      end
    end
  end

  test "build_mws_messages should work for product image data" do
    r_image = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[3], :message_type=>MwsRequest::FEED_MSGS[3])
    l_image = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', 
                    :product_id=>@p.id, :parent_listing_id=>@l_product.id)
 
 	  assert_difference('MwsMessage.count',CHILD_ROWS*IMAGES_PER_CHILD) do
	    a = l_image.build_mws_messages(r_image)
      assert_kind_of Array, a
      r_image.message = a
      r_image.save
      
      assert_difference('MwsResponse.count',1) do
        response = r_image.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
      end
    end
  end

  test "build_mws_messages should work for inventory availability" do
    r_inventory = FactoryGirl.create(:mws_request, :store_id=>@s.id, :request_type=>'SubmitFeed', 
                    :feed_type=>MwsRequest::FEED_STEPS[4], :message_type=>MwsRequest::FEED_MSGS[4])
    l_inventory = FactoryGirl.create(:listing, :store_id=>@s.id, :operation_type=>'Update', 
                    :product_id=>@p.id, :parent_listing_id=>@l_product.id)
 
 	  assert_difference('MwsMessage.count',CHILD_ROWS) do
	    a = l_inventory.build_mws_messages(r_inventory)
      assert_kind_of Array, a
      r_inventory.update_attributes(:message => a)
      
      assert_difference('MwsResponse.count',1) do
        response = r_inventory.submit_mws_feed(@s,false,false)
        assert_equal '_SUBMITTED_', response.processing_status
        assert_equal '5023807698', response.feed_submission_id
        assert_equal 'bca661a7-e843-4e67-b4cb-dea42c766300', response.amazon_request_id
      end
    end
  end

  test "sync_mws_listings should work synchronously" do
    expected_messages_count = (PARENT_ROWS+CHILD_ROWS)+(PARENT_ROWS)+(CHILD_ROWS)+(CHILD_ROWS*IMAGES_PER_CHILD)+(CHILD_ROWS)
    assert_equal 0, MwsMessage.count
 	  assert_difference('Listing.count',0) do
 	    assert_difference('MwsMessage.count',expected_messages_count) do      
        assert_difference('MwsRequest.count',STEPS_PER_FEED*REQUESTS_PER_STEP) do
          assert_difference('MwsResponse.count',STEPS_PER_FEED*REQUESTS_PER_STEP) do
	          response = @s.sync_mws_listings(false)
	          pr = response.mws_request
	          assert_equal 'SubmitFeed', pr.request_type
	          assert_equal MwsRequest::FEED_STEPS[0], pr.feed_type
	          assert_equal STEPS_PER_FEED-1 + REQUESTS_PER_STEP-1, pr.sub_requests.count
	          assert_equal 1, pr.listings.count
	          assert_equal expected_messages_count, pr.listings[0].mws_messages.count
          end
        end
      end
    end
  end
  
  test "sync_mws_listings should work asynchronously" do
   	assert_difference('Listing.count',0) do
   	  assert_difference('MwsMessage.count',STEPS_PER_FEED) do      
        assert_difference('MwsRequest.count',1) do
          assert_difference('MwsResponse.count',0) do
  	        response = @s.sync_mws_listings
  	        assert_kind_of Delayed::Backend::ActiveRecord::Job, response
          end
        end
      end
    end
  end    

end