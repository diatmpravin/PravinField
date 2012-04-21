require 'test_helper'

class SkuPatternTest < ActiveSupport::TestCase

  test "split_sku should work" do
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]", :delimiter=>'-')
    sku = 'ZZZ-A/AA-3456-ZZZZ'
    
    # pattern only has 2 '-' delimiters, so only split based on the first two
    assert_equal ['ZZZ','A/AA','3456-ZZZZ'], sp.split_sku(sku)
  end

  test "self.parse should work" do
    sku = 'zzz-AAA-34'
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')", :priority=>2.0)

    # Test expected output with only one SKU Pattern loaded.  Matches case of input SKU.
    expected_hash = {:product_sku=>'zzz', :color1_code=>'AAA-34' } 
    assert_equal expected_hash, SkuPattern.parse(sp.brand, sku)    
    
    # Test expected output with multiple SKU Patterns loaded, confirms priority is working
    sp2 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]", :priority=>1.0, :brand_id=>sp.brand_id)
    expected_hash = {:product_sku=>'zzz', :color1_code=>'AAA', :size=>'34' } 
    assert_equal expected_hash, SkuPattern.parse(sp.brand, sku)
  end
  
  test "parse should work" do
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]")    
    sku = 'ZZZ-AAA-34'
    expected_hash = {:product_sku=>'ZZZ', :color1_code=>'AAA', :size=>'34' } 
    assert_equal expected_hash, sp.parse(sku)
  end
  
  test "extract_vars should work" do
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]")
    assert_equal [:product_sku,:color1_code,:size], sp.extract_vars
  end

  #TODO test evaluate in isolation, in self.evaluate test, only test that it works for multiple
  test "evaluate should work" do
    p = FactoryGirl.create(:product, :sku=>'al170')
    v = FactoryGirl.create(:variant, :product_id=>p.id, :color1_code=>'S-104-302')
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}", :brand_id=>p.brand.id)
    assert_equal p.brand, v.brand
    assert_equal sp, v.brand.sku_patterns.first
    assert_equal "AL170-S-104-302", v.get_clean_sku
  end  

  test "self.evaluate should work" do
    b = FactoryGirl.create(:brand)
    p = FactoryGirl.create(:product, :brand_id=>b.id, :sku=>'www')
    v = FactoryGirl.create(:variant, :product_id=>p.id, :sku=>'xx/x', :color1_code=>'yy/y', :size=>'zz-z')
    sv = FactoryGirl.create(:sub_variant, :variant_id=>v.id, :sku=>'37.0')
    
    sp1 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size}[0,2]", :brand_id=>b.id)
    sp2 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]", :brand_id=>b.id)
    sp3 = FactoryGirl.create(:sku_pattern, :pattern=>"{sku}[0..-3]", :brand_id=>b.id)
    sp4 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}", :brand_id=>b.id)
    sp5 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','-')", :brand_id=>b.id)
    sp6 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','-')", :brand_id=>b.id)
    sp7 = FactoryGirl.create(:sku_pattern, :pattern=>"{sku}[0..-3]", :condition=>"{sku}[-2,2]=='.0'", :brand_id=>b.id, :granularity=>'SubVariant')
  
    a = SkuPattern.evaluate(v)
    assert_kind_of Array, a
    assert_equal 6, a.length
    assert_kind_of String, a.first
    assert_equal "www-yy/y-zz".upcase, a[0]
    assert_equal "www-yyy-zz".upcase, a[1]
    assert_equal "xx".upcase, a[2]
    assert_equal "www-yy/y".upcase, a[3]
    assert_equal "www-yy-y".upcase, a[4]
    assert_equal v.sku.upcase, a[5] # tests that the array returned is unique, 6 items instead of 7
  
    # the pattern condition is met so the .0 is chopped off
    b = SkuPattern.evaluate(sv)
    assert_kind_of Array, b
    assert_equal 2, b.length  # should be length 2, ['37.0','37']
    assert_kind_of String, b.first
    assert_equal '37', b.first
    
    # Evaluates to itself as the pattern condition is not met
    sv.sku = '37.5'
    sv.save
    c = SkuPattern.evaluate(sv)
    assert_equal 1, c.length
    assert_equal '37.5', c.first
  end
  
end