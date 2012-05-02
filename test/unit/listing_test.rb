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
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render
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
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render        
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
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render
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
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render
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
        #puts Amazon::MWS::FeedBuilder.new(response.mws_request.message_type, response.mws_request.message, {:merchant_id => 'DUMMY'}).render        
        #puts response.mws_request.message
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

  test "sync_mws_listings should work LIVE" do
    pending
    @s2 = FactoryGirl.create(:store, :store_type=>'MWS', :name=>'FieldDay')
	  @listing = FactoryGirl.create(:listing, :store_id=>@s2.id, :operation_type=>'Update', :product_id=>@p.id)
    #response = @s2.sync_mws_listings
  end

end