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
	
end
