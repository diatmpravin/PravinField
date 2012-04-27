require 'test_helper'

class SkuPatternTest < ActiveSupport::TestCase

  test "self.parse usage examples" do
    # Emporio Armani (Safilo)
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}+'-'+{color2_code}[0,2]"},'EA9752-0GLN-CC', {:product_sku=>'EA9752', :color1_code=>'0GLN', :color2_code=>'CC'} )
    
    # Arnette
    brand_pattern_test({:pattern=>"{product_sku2}+'-'+{color1_code}", :granularity=>'Variant'},
      'AN3061-01', {:product_sku2=>'AN3061', :color1_code=>'01'}, 'AN-OneTime')

    brand_pattern_test({:pattern=>"{sku}", :granularity=>'Variant', :delimiter=>'.'},'800-0001', {:sku=>'800-0001'})
    #TODO Need to handle a condition, but condition must have access to fields?  {product_sku}[0,3]=='AN-'

    # Bell
    brand_pattern_test({:pattern=>"{sku}", :granularity=>'SubVariant', :delimiter=>'.'},'Bell-2012382', {:sku=>'Bell-2012382'})
          
    # Blackhawk - need to handle fixed length delimit
    brand_pattern_test({:pattern=>"{product_sku}[0,6]+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},"84BS04BK-SM", {:color1_code=>'BK', :size_code=>'SM'}, '84BS04')
    
    # Brooks (shoes) uses . delimiter and size_code
    brand_pattern_test({:pattern=>"{product_sku}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.'},'1000111D106.050', {:product_sku=>'1000111D106', :size_code=>'050'})
          
    # See row 13817, size ONE isn't stored in size column, if there is no size, then set size according to ...
    
    # Ed Hardy (Parent SKU has dashes as well)
    # Need to pass a hash of known entities for substitution before parsing?
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'SubVariant'},"EHS-001-BLACK", {:color1_code=>'BLACK'}, 'EHS-001')
    
    # Electric Visual
    # TODO need conditions
    # Color codes are consistent, but not delimited, so no hope there, just store in color1_code
    brand_pattern_test({:pattern=>"{product_sku}.gsub('EV-','')+'-'+{color1_code}", :granularity=>'Variant'},'09-10639', {:color1_code=>'10639'}, 'EV-09')
    brand_pattern_test({:pattern=>"{product_sku}.gsub('EV-','')+'-'+{color1_code}", :granularity=>'Variant'},'10-10639-AZ16', {:color1_code=>'10639'}, 'EV-10')        
    brand_pattern_test({:pattern=>"{product_sku}+{color1_code}", :granularity=>'Variant'},'EG0109001', {:color1_code=>'09001'}, 'EG01')
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant'},'EG0110001-BRO', {:color1_code=>'BRO'}, 'EG0110001')  
    
    # Fox - no relationship
    #parent_sku = "Fox-Cadet"
    #sku = "30-097"
    #sku = "FX6003-01"
    
    # Gargoyles - no relationship
    #parent_sku = "85's"
    #sku = "3346016A"
    
    # Giro - no relationship
    #Giro-Advantage2
    #Giro-108742
    
    # Helly Hansen, leading zeros lopped off
    #parent_sku = "6304"  sku = "06304-171-3"
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},'06304-171-3', {:product_sku=>'06304', :color1_code=>'171', :size_code=>'3'})    
    
    # Injinji, need to pass in parent_sku as it contains a dash
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},'INJ-1-BLK-L', {:color1_code=>'BLK', :size_code=>'L'}, 'INJ-1')
    
    # Julbo, no relationship
    # Kaenon, no relationship    
    # Karhu, normal product_sku-size_code
    # Karl Lagerfeld standard product_sku-color1_code
    # Kate Spade just like Safilo
    # Lacoste product_sku-color1_code
    # Louis Garneau has had leading zeros lopped off, but otherwise product_sku-color1_code-size_code
    
    # Maui Jim prefix and suffix
    brand_pattern_test({:pattern=>"{color2_code}+{product_sku}+'-'+{color1_code}"},'H805-1015', {:color1_code=>'1015', :color2_code=>'H'}, '805')
    brand_pattern_test({:pattern=>"{color2_code}+{product_sku}+'-'+{color1_code}"},'R101-13', {:color1_code=>'13', :color2_code=>'R'}, '101')
    brand_pattern_test({:pattern=>"{color2_code}+{product_sku}+'-'+{color1_code}"},'G805-0215', {:color1_code=>'0215', :color2_code=>'G'}, '805')
    brand_pattern_test({:pattern=>"{color2_code}+{product_sku}+'-'+{color1_code}"},'577-03', {:color1_code=>'03', :color2_code=>''}, '577')
    
    # MErcedes Benz is ok product_sku-color1_code
    # Michael Kors is the same
    
    # Mizuno was changed to scientific notation
    brand_pattern_test({:pattern=>"{product_sku}.gsub('MA-','')+'.'+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.-'},'420983.001F-10', {:color1_code=>'001F', :size_code=>'10'},'MA-420983')
    brand_pattern_test({:pattern=>"{product_sku}.gsub('MA-','')+'.'+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.-'},'420983.001F-10', {:color1_code=>'001F', :size_code=>'10'},'420983')
    brand_pattern_test({:pattern=>"{product_sku}.gsub('MA-','')+'.'+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.-'},'410335.001F-10', {:product_sku=>'410335', :color1_code=>'001F', :size_code=>'10'})    
    brand_pattern_test({:pattern=>"{product_sku}.gsub('MA-','')+'.'+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.-'},'420960.9090.XXL', {:product_sku=>'420960', :color1_code=>'9090', :size_code=>'XXL'})
      
    # Moving comfort - fixed with, 6 digit product sku    
    brand_pattern_test({:pattern=>"{product_sku}+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.'},'300016001.025', {:color1_code=>'001', :size_code=>'025'}, '300016')
    brand_pattern_test({:pattern=>"{product_sku}+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.'},'350014511.0442D', {:color1_code=>'511', :size_code=>'0442D'}, '350014')
        
    # Native, need to lop off the NV-
    brand_pattern_test({:pattern=>"{product_sku}.gsub('NV-','')+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},'102-300-521B', {:color1_code=>'300', :size_code=>'521B'}, 'NV-102')
    
    # Nautica is normal
    
    # Nike - may want to use product.sku2
    brand_pattern_test({:pattern=>"{product_sku2}+'-'+{color1_code}"},'EV0474-001', {:product_sku2=>'EV0474', :color1_code=>'001'}, 'Nike-Impel')
    
    # Oakley
    brand_pattern_test({:pattern=>"{color2_code}+'-'+{color1_code}"},'001-0001', {:color1_code=>'0001', :color2_code=>'001'}, 'OROKRPro')    
    b = FactoryGirl.create(:brand)
    assert_nil SkuPattern.parse(b, '001-0001', 'OROKRPro')

    # Oakley Apparel    # TODO needs conditions
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},'411373-747-XXL', {:product_sku=>'411373', :color1_code=>'747', :size_code=>'XXL'})    
    
    # Pearl izumi, drop the P?
    brand_pattern_test({:pattern=>"{product_sku}.gsub('P','')+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},'0256-021-LG', {:color1_code=>'021', :size_code=>'LG'}, 'P0256')
    
    # Ralph Lauren, D&G normal
    
    # Ray Ban
    #RB3296-0038G-67
    #RB3339-006-5916
    #RB3332-006-6417
    #RB4154-80351-57
    #RB8307-014N6-58
    #RB4153-821M2-62
    
    # Revo normal
    # Roxy normal
    # Salomon is corrupt, missing parents
    # Serengeti no relationship
    # Sherpani, parent sku includes a dash, otherwise ok
    # Smith no relationship
    # Sole just has Sole-{color1_code}-{size_code}
    # Spy no relationship, and problem with scientific notation
    
    # Sugoi
    brand_pattern_test({:pattern=>"{product_sku}+'.'+{color1_code}+'.'+{size_code}", :granularity=>'SubVariant', :delimiter=>'.'},
      '10203F.BLK.1', {:product_sku=>'10203F', :color1_code=>'BLK', :size_code=>'1'})    
    
    # Suncloud
    # no relationship
    
    # Tag Hueuer - Leading zeros truncated for products
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}"},'0204-01', {:product_sku=>'0204', :color1_code=>'01'})
    
    # Tifosi - missing parent relationships
    #product_sku = 'T-F005'
    
    # Timbuk2 - truncate product sku
    brand_pattern_test({:pattern=>"{product_sku}.gsub('TB2-','')+'-'+{size_code}+'-'+{color1_code}", :granularity=>'SubVariant'},'902-4-2000', {:size_code=>'4', :color1_code=>'2000'}, 'TB2-902')    
        
    # Valentino normal Safilo patern
    
    # Vestal - no relationship
    
    # Von Zipper
    brand_pattern_test({:pattern=>"{product_sku2}+'-'+{color1_code}"},'SJJF5BAN-BKG', {:product_sku2=>'SJJF5BAN', :color1_code=>'BKG'}, 'VZ-Banshee')
    
    # Wiley X - no relationship
    
    # Zoot - sometimes need to shop leading Z from product_sku, sometimes  have it for variant sku
    brand_pattern_test({:pattern=>"{product_sku}+{size_code}", :granularity=>'SubVariant'},'ZF9UCC0111', {:size_code=>'11'}, 'ZF9UCC01')
    #condition = "{product_sku}[0,1]!='Z' && {sku}[0,1]=='Z'"
    brand_pattern_test({:pattern=>"'Z'<<{product_sku}+{size_code}", :granularity=>'SubVariant'},'ZS9AH0110', {:size_code=>'10'}, 'S9AH01')
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant'},'S8WTT56-SP-L', {:product_sku=>'S8WTT56', :color1_code=>'SP', :size_code=>'L'})
    brand_pattern_test({:pattern=>"{product_sku}+'-'+{size_code}", :granularity=>'SubVariant'},'S9WRS02-6.5', {:product_sku=>'S9WRS02', :size_code=>'6.5'})
  end
    
  test "parse should work" do
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}.gsub('/','')+'-'+{size}[0,2]")    
    sku = 'ZZZ-AAA-34'
    expected_hash = {:product_sku=>'ZZZ', :color1_code=>'AAA', :size=>'34' } 
    assert_equal expected_hash, sp.parse(sku)
  end
  
  test "self.parse_variant should work" do
    b = FactoryGirl.create(:brand)
    sp = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant', :brand_id=>b.id)
    sp2 = FactoryGirl.create(:sku_pattern, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant', :brand_id=>b.id)
    product_sku = 'MT1599D'
    h = SkuPattern.parse_variant(b, 'MT1599D-BLK-XS', product_sku)
    h2 = SkuPattern.parse_variant(b, 'MT1599D-BLK-S', product_sku)
    assert_equal 'MT1599D-BLK', h[:variant_sku]
    assert_equal 'MT1599D-BLK', h2[:variant_sku]
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