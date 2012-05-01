require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'

include Amazon::MWS

IMAGE_FILE_NAME = 'logo.png'
LOCAL_IMAGE_PATH = 'test/fixtures/images/'
LOCAL_IMAGE = LOCAL_IMAGE_PATH+IMAGE_FILE_NAME
LOCAL_IMAGE2 = LOCAL_IMAGE_PATH+'logo2.png'
LOCAL_IMAGE3 = LOCAL_IMAGE_PATH+'logo3.png'
LOCAL_IMAGE4 = LOCAL_IMAGE_PATH+'logo4.png'
REMOTE_IMAGE = 'http://cdn.shopify.com/s/files/1/0109/9112/t/4/assets/'+IMAGE_FILE_NAME

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  # Add more helper methods to be used by all tests here...

	def xml_for(name, code)
	  file = File.open(Pathname.new(File.dirname(__FILE__)).expand_path.dirname.join("test/fixtures/xml/#{name}.xml"),'rb')
	  mock_response(code, {:content_type=>'text/xml', :body=>file.read})
	end

	def mock_response(code, options={})
	  body = options[:body]
	  content_type = options[:content_type]
	  response = Net::HTTPResponse.send(:response_class, code.to_s).new("1.0", code.to_s, "message")
	  response.instance_variable_set(:@body, body)
	  response.instance_variable_set(:@read, true)
	  response.content_type = content_type
	  return response
	end
	
  def brand_pattern_test(sp_hash, sku, expected_hash, product_sku = nil)
    # create an SKU Pattern to test
    sp = FactoryGirl.create(:sku_pattern, sp_hash)
    
    # parse an input brand, sku, and product-sku according to the pre-existing sku pattern
    h = SkuPattern.parse(sp.brand, sku, product_sku)
    assert_equal expected_hash, h
    
    # create product, variant, and sub_variant as appropriate
    p = FactoryGirl.create(:product, :sku=>product_sku, :brand=>sp.brand)
    #TODO lookup p using SkuMapping?
    
    #TODO do something meaningful like update the Variant / SubVariant
    obj = SkuMapping.get_catalog_match(sku)
    if !obj.nil?
      return
    end
    
    # TODO check if this variant has already been created, add unique constraints, something
    # by product_id, color1_code, color2_code, size_code?? But size_code will be confused with SubVariant
    if sp.granularity=='SubVariant'
      v = FactoryGirl.create(:variant, :product_id=>p.id, :color1_code=>h[:color1_code], :color2_code=>h[:color2_code])
      sv = FactoryGirl.create(:sub_variant, :sku=>sku, :size_code=>h[:size_code], :size=>h[:size], :variant_id=>v.id)
      sku_arr = SkuPattern.evaluate(sv)
      assert sku_arr.include?(sku.upcase), "sku is #{sku}, sku_arr is #{sku_arr.to_s}"
      o = FactoryGirl.create(:mws_order_item, :seller_sku=>sku)      
      assert_equal sv, o.sub_variant
      assert_equal v, o.variant
      assert_equal sv, SkuMapping.get_catalog_match(o.clean_sku)      
    else
      v = FactoryGirl.create(:variant, :product_id=>p.id, :color1_code=>h[:color1_code], :color2_code=>h[:color2_code], :sku=>sku, :size=>h[:size], :size_code=>h[:size_code])
      assert SkuPattern.evaluate(v).include?(sku)
      o = FactoryGirl.create(:mws_order_item, :seller_sku=>sku)      
      assert_equal v, o.variant
      assert_equal v, SkuMapping.get_catalog_match(o.clean_sku) 
    end
  end	

  class ActionController::TestCase
    include Devise::TestHelpers
  end
    
end

