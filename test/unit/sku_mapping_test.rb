require 'test_helper'

class SkuMappingTest < ActiveSupport::TestCase

	test "get_catalog_match should work" do
		p = FactoryGirl.create(:product)
		sm = FactoryGirl.create(:sku_mapping, :sku=>p.base_sku, :granularity=>'product', :foreign_id=>p.to_param)
		assert_equal p, sm.get_catalog_match
		assert_equal p, SkuMapping.get_catalog_match(p.base_sku)
		assert_nil SkuMapping.get_catalog_match('unmatched_sku')
		
    v = FactoryGirl.create(:variant, :product_id=>p.to_param)
		sm2 = FactoryGirl.create(:sku_mapping, :sku=>v.sku, :granularity=>'variant', :foreign_id=>v.to_param)
		assert_equal v, sm2.get_catalog_match
		assert_equal v, SkuMapping.get_catalog_match(v.sku)

    sv = FactoryGirl.create(:sub_variant, :variant_id=>v.to_param)
		sm3 = FactoryGirl.create(:sku_mapping, :sku=>sv.sku, :granularity=>'sub_variant', :foreign_id=>sv.to_param)
		assert_equal sv, sm3.get_catalog_match
		assert_equal sv, SkuMapping.get_catalog_match(sv.sku)
	end

end
