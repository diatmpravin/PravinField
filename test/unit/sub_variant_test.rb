require 'test_helper'

class SubVariantTest < ActiveSupport::TestCase

	test "sku should be unique" do
		v = FactoryGirl.create(:variant)
		sv = FactoryGirl.create(:sub_variant, :variant => v)
		sv2 = FactoryGirl.create(:sub_variant, :variant => v)
		assert sv2.valid?
		sv2.sku = sv.sku
		assert sv2.invalid?
	end
	
	test "search should work" do
		p = FactoryGirl.create(:product)
		v = FactoryGirl.create(:variant, :product_id => p.id, :sku => 'Ray-Bans')
		sv1 = FactoryGirl.create(:sub_variant, :variant_id=>v.id, :upc=>'Oakley1')
		sv2 = FactoryGirl.create(:sub_variant, :variant_id=>v.id, :size=>'Oakley2')
		
		v2 = FactoryGirl.create(:variant, :product_id => p.id, :sku => 'Ray-Bans2')
		sv3 = FactoryGirl.create(:sub_variant, :variant_id=>v2.id, :upc=>'Annie1')
    sv4 = FactoryGirl.create(:sub_variant, :variant_id=>v2.id, :size=>'Annie2')
		
		p2 = FactoryGirl.create(:product)
		v3 = FactoryGirl.create(:variant, :product_id => p2.id, :sku => 'Ray-ABC345')
		sv5 = FactoryGirl.create(:sub_variant, :variant_id=>v3.id, :upc=>'Hall1')
		sv6 = FactoryGirl.create(:sub_variant, :variant_id=>v3.id, :upc=>'Oakley3')
		
		p3 = FactoryGirl.create(:product)

		# search term partially matching 2 products
		arr = SubVariant.search('Oakley')
		assert_equal 2, arr.length
		assert arr.include?(p.id)
		assert arr.include?(p2.id)
		
		# search term matching a product via two variants
		arr = SubVariant.search('Annie')
		assert_equal 1, arr.length
		assert_equal v.product_id, arr[0]
		
		# search term matching back half of string only matching 1 product
		arr = SubVariant.search('ll1')
		assert_equal 1, arr.length
		assert_equal v3.product_id, arr[0]
		
		# search term should not match any products
		arr = SubVariant.search('xxx')
		assert arr.empty?
	end

end
