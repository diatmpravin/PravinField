require 'test_helper'

class SkuMappingTest < ActiveSupport::TestCase

	test "self.get_catalog_match should work" do
		p = FactoryGirl.create(:product)
		sm = FactoryGirl.create(:sku_mapping, :sku=>p.base_sku, :sku_mapable_type=>'Product', :sku_mapable_id=>p.id)
		assert_equal p, SkuMapping.get_catalog_match(p.base_sku)
		assert_nil SkuMapping.get_catalog_match('unmatched_sku')
		
    v = FactoryGirl.create(:variant, :product_id=>p.to_param)
		sm2 = FactoryGirl.create(:sku_mapping, :sku=>v.sku, :sku_mapable_type=>'Variant', :sku_mapable_id=>v.id)
		assert_equal v, SkuMapping.get_catalog_match(v.sku)

    sv = FactoryGirl.create(:sub_variant, :variant_id=>v.to_param)
		sm3 = FactoryGirl.create(:sku_mapping, :sku=>sv.sku, :sku_mapable_type=>'SubVariant', :sku_mapable_id=>sv.id)
		assert_equal sv, SkuMapping.get_catalog_match(sv.sku)
	end
	
end
