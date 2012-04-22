require 'test_helper'

class SkuMappingTest < ActiveSupport::TestCase

	test "self.get_catalog_match should work" do
		p = FactoryGirl.create(:product, :sku=>'AAA')
		assert_equal p, SkuMapping.get_catalog_match(p.sku)
		assert_nil SkuMapping.get_catalog_match('unmatched_sku')
		
    v = FactoryGirl.create(:variant, :product_id=>p.to_param, :sku=>'AAA-BBB')
		assert_equal v, SkuMapping.get_catalog_match(v.sku)

    sv = FactoryGirl.create(:sub_variant, :variant_id=>v.to_param, :sku=>'AAA-BBB-CCC')
		assert_equal sv, SkuMapping.get_catalog_match(sv.sku)
	end
	
end
