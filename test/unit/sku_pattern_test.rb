require 'test_helper'

class SkuPatternTest < ActiveSupport::TestCase

  test "self.evaluate should work" do
    b = FactoryGirl.create(:brand)
    p = FactoryGirl.create(:product, :brand_id=>b.id, :base_sku=>'www')
    v = FactoryGirl.create(:variant, :product_id=>p.id, :sku=>'xx/x', :color1_code=>'yy/y', :size=>'zz-z')
    sv = FactoryGirl.create(:sub_variant, :variant_id=>v.id, :sku=>'37.0')
    
    sp1 = FactoryGirl.create(:sku_pattern, :pattern=>"{base_sku}+'-'+{color1_code}+'-'+{size}[0,2]", :brand_id=>b.id)
    sp2 = FactoryGirl.create(:sku_pattern, :pattern=>"{base_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]", :brand_id=>b.id)
    sp3 = FactoryGirl.create(:sku_pattern, :pattern=>"{sku}[0..-3]", :brand_id=>b.id)
    sp4 = FactoryGirl.create(:sku_pattern, :pattern=>"{base_sku}+'-'+{color1_code}", :brand_id=>b.id)
    sp5 = FactoryGirl.create(:sku_pattern, :pattern=>"{base_sku}+'-'+{color1_code}.gsub('/','-')", :brand_id=>b.id)
    sp6 = FactoryGirl.create(:sku_pattern, :pattern=>"{sku}", :brand_id=>b.id)
    sp7 = FactoryGirl.create(:sku_pattern, :pattern=>"{sku}[0..-3]", :condition=>"{sku}[-2,2]=='.0'", :brand_id=>b.id, :granularity=>'SubVariant')
  
    h = { 
      'brand'=>v.brand.name,
      'sku'=>v.sku,
      'base_sku'=>v.product.base_sku, 
      'color1_code'=>v.color1_code,
      'size'=>v.size
    }
    a = SkuPattern.evaluate(v, h)
    assert_kind_of Array, a
    assert_equal 6, a.length
    assert_kind_of String, a.first
    assert_equal "www-yy/y-zz", a[0]
    assert_equal "www-yyy-zz", a[1]
    assert_equal "xx", a[2]
    assert_equal "www-yy/y", a[3]
    assert_equal "www-yy-y", a[4]
    assert_equal v.sku, a[5] # tests that the array returned is unique, 6 items instead of 7
  
    # the pattern condition is met so the .0 is chopped off
    h['sku'] = sv.sku
    b = SkuPattern.evaluate(sv, h)
    assert_kind_of Array, b
    assert_equal 2, b.length
    assert_kind_of String, b.first
    assert_equal '37', b.first
    
    # Evaluates to itself as the pattern condition is not met
    h['sku'] = '37.5'
    c = SkuPattern.evaluate(sv, h)
    assert_equal 1, c.length
    assert_equal '37.5', c.first
  end
  
end