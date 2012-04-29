require 'test_helper'

class ProductTest < ActiveSupport::TestCase
	
	test "variants relation should work" do
		p = FactoryGirl.create(:product)
		assert_equal 0, p.variants.count
		v = FactoryGirl.create(:variant, :product => p)
		assert_equal 1, p.variants.count
		v2 = FactoryGirl.create(:variant, :product => p)
		assert_equal 2, p.variants.count
	end
	
	test "brand should be valid" do
		p = FactoryGirl.build(:product)
		assert p.valid?
		p.brand_id = nil
		assert p.invalid?
	end
	
	test "sku should be unique" do
		b = FactoryGirl.create(:brand)
		p = FactoryGirl.create(:product, :sku => 'NotUnique', :brand => b)
		p2 = FactoryGirl.build(:product, :sku => 'NotUnique', :brand => b)
		assert p2.invalid?
		assert p2.errors[:sku].any?
	end
			
	test "search should work" do
		p = FactoryGirl.create(:product, :name => 'Carmichel')
		v = FactoryGirl.create(:variant, :product => p, :sku => 'Ray-Bans')
		v2 = FactoryGirl.create(:variant, :product => p, :sku => 'Ray-Bans2')
		p2 = FactoryGirl.create(:product, :name => 'Carmichel')
		v3 = FactoryGirl.create(:variant, :product => p2, :sku => 'Ray-ABC345')
		p3 = FactoryGirl.create(:product, :name => 'Nonsense')
		
		# search term matching a single order via two items
		arr = Product.search('Ray-Ban')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal 1, arr.length
		assert_equal p, arr[0]
		
		# search term partially matching 2 orders
		arr = Product.search('Ray-')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal 2, arr.length
		assert arr.include?(p)
		assert arr.include?(p2)

		arr = Product.search('Carmichel')
		assert_equal 2, arr.length
		assert arr.include?(p)
		assert arr.include?(p2)		
		
		# search term matching back half of string only matching 1 order
		arr = Product.search('ABC')
		assert_instance_of ActiveRecord::Relation, arr
		assert_equal 1, arr.length
		assert_equal p2, arr[0]
		
		# search term should not match any orders
		arr = Product.search('xxx')
		assert_instance_of ActiveRecord::Relation, arr
		assert arr.empty?
	end
	
	test "refresh all sku mappings should work" do
	  b = FactoryGirl.create(:brand)
	  p = FactoryGirl.create(:product, :brand_id=>b.id, :sku=>'xxxx')
	  v = FactoryGirl.create(:variant, :product_id=>p.id, :size=>'34', :color1_code=>'RCGS', :sku=>'abcd')
    sv = FactoryGirl.create(:sub_variant, :variant_id=>v.id, :sku=>'1234')

	  assert_equal 'xxxx', p.reload.sku
	  assert_equal 'abcd', v.reload.sku
	  assert_equal '1234', sv.reload.sku

	  SkuMapping.where(:source=>'auto').destroy_all
	  assert_equal 0, SkuMapping.count
	  
    # refresh all sku mappings should completely regenerate the "auto" mappings for variants and subvariants
	  Product.refresh_all_sku_mappings
	  
	  # sku mapping count should have rebuilt, even with no patterns should at least take the skus
	  assert SkuMapping.count > 0
	end
		
		
	test "attributes_for_amazon should work" do
	  p = FactoryGirl.create(:product, :search_keywords=>"term1\rterm2\rterm3")
	  v1 = FactoryGirl.create(:variant, :product_id=>p.id, :msrp=>10.00, :price=>10.00, :sale_price=>9.00)
	  v2 = FactoryGirl.create(:variant, :product_id=>p.id, :msrp=>10.00, :price=>10.00, :sale_price=>9.00)
	  sv1 = FactoryGirl.create(:sub_variant, :variant_id=>v1.id, :upc=>'23432343432')
	  sv2 = FactoryGirl.create(:sub_variant, :variant_id=>v1.id, :upc=>'23432343433')
	  sv3 = FactoryGirl.create(:sub_variant, :variant_id=>v2.id, :upc=>'23432343434')
	  sv4 = FactoryGirl.create(:sub_variant, :variant_id=>v2.id, :upc=>'23432343435')
	  vi1 = FactoryGirl.create(:variant_image, :variant_id=>v1.id)
	  vi2 = FactoryGirl.create(:variant_image, :variant_id=>v1.id)
	  vi3 = FactoryGirl.create(:variant_image, :variant_id=>v2.id)
	  vi4 = FactoryGirl.create(:variant_image, :variant_id=>v2.id)	  
	  
	  a = p.attributes_for_amazon(:product_data)
	  assert_kind_of Array, a
	  assert_kind_of Hash, a[0]
	  
	  a = p.attributes_for_amazon(:product_relationship_data)
	  assert_kind_of Array, a
	  assert_kind_of Hash, a[0]
	  
	  a = p.attributes_for_amazon(:product_image_data)
	  assert_kind_of Array, a
	  assert_kind_of Hash, a[0]

    a = p.attributes_for_amazon(:product_pricing)
    assert_kind_of Array, a
    assert_kind_of Hash, a[0]
	  #puts a
    
    big picture
    
    - select one or more products and add these to the sync queue
    - can select another product and add it to the queue
    - can review the queue
    - queue consists of listings with a certain state
    - when a sync is run for a given store, every incomplete listing for that store is taken
    - these listings are converted to XML format appropriately using FeedBuilder
    - the XML is stored in the appropriate field of the listing table?  Or is it simply stored in the request
    - we can search for products, variant, or subvariants that have been updated post their last listing
    
    - A GetFeedSubmissionList is sent periodically
    - Amazon returns if processing is complete or not
    - if not complete, another GetFeedSubmissionList
    
    
    
    
	  
	end	
end
