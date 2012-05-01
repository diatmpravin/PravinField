require 'test_helper'

class ImportTest < ActiveSupport::TestCase

  TEST_FILENAME = 'test/fixtures/csv/2XU.txt'
  ERROR_FILENAME = 'test/fixtures/csv/2XU_errors.txt'
    
  test "process_input_file should work" do
    
    header_rows = 2
    product_rows = 3
    variant_rows = 4
    valid_sub_variant_rows = 22
    error_sub_variant_rows = 2
    total_rows = product_rows + valid_sub_variant_rows + error_sub_variant_rows
    
    # should get a brand error on every row
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', 0) do
          i = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))
          i.process_input_file
          assert_equal (header_rows+product_rows+valid_sub_variant_rows+error_sub_variant_rows), File.open(i.error_file.path).readlines.size          
          assert_equal "0 products, 0 variants, 0 sub_variants, #{total_rows} errors", i.status
          i.destroy
        end
      end
    end
    
    # add the brand
    b = FactoryGirl.create(:brand, :name=>'2XU')
    
    # should still get a missing sub_variant sku pattern on every row
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', 0) do
          i2 = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))
          i2.process_input_file
          assert_equal (header_rows+product_rows+valid_sub_variant_rows+error_sub_variant_rows), File.open(i2.error_file.path).readlines.size          
          assert_equal "0 products, 0 variants, 0 sub_variants, #{total_rows} errors", i2.status
          i2.destroy
        end
      end
    end

    # add the sub_variant sku pattern
    sp2 = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')

    # should still get a missing variant sku pattern for every variant row
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', 0) do
          i3 = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))
          i3.process_input_file
          assert_equal (header_rows+product_rows+valid_sub_variant_rows+error_sub_variant_rows), File.open(i3.error_file.path).readlines.size
          assert_equal "0 products, 0 variants, 0 sub_variants, #{total_rows} errors", i3.status
          i3.destroy
        end
      end
    end

    # add the variant sku pattern
    sp = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')

    # should work
    assert_difference('Product.count', product_rows) do
      assert_difference('Variant.count', variant_rows) do
        assert_difference('SubVariant.count', valid_sub_variant_rows) do # 60 sub_variant rows, but the last two are invalid
          i4 = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))
          i4.process_input_file
          assert_equal (header_rows+error_sub_variant_rows), File.open(i4.error_file.path).readlines.size
          assert_equal "#{product_rows} products, #{variant_rows} variants, #{valid_sub_variant_rows} sub_variants, #{error_sub_variant_rows} errors", i4.status
          i4.destroy
        end
      end
    end
    
    # reprocessing the errors should work
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', error_sub_variant_rows) do
          i5 = FactoryGirl.create(:import, :input_file => File.new(ERROR_FILENAME))
          i5.process_input_file
          assert i5.error_file.to_s.blank?
          assert_equal "0 products, 0 variants, #{error_sub_variant_rows} sub_variants, 0 errors", i5.status          
          i5.destroy
        end
      end
    end
    
  end

  test "find or create product from csv should work" do
    b = FactoryGirl.create(:brand, :name=>'2XU')
    sp = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')
    sp2 = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
    i = FactoryGirl.create(:import)
    
    # a new product that doesn't already exist
    rows = CSV.read(TEST_FILENAME, { :headers=>Import::H, :col_sep => "\t", :skip_blanks => true })
    row = rows[2]
    assert_equal 'parent', row.field('parent-child')
    p = i.find_or_create_product_from_csv(row)
    assert_equal row.field('product-name'), p.name
    assert_equal row.field('sku'), p.sku

    # an existing product
    row = rows[9]
    assert_equal 'parent', row.field('parent-child')
    p2 = FactoryGirl.create(:product, :sku=>row.field('sku'), :department=>'replace me')
    p2_from_csv = i.find_or_create_product_from_csv(row)
    assert_equal p2.id, p2_from_csv.id
    assert_equal row.field('product-name'), p2_from_csv.name
    p2_from_csv = Product.find(p2.id)
    assert_equal row.field('product-name'), p2_from_csv.name
    
    # a subvariant row of an existing product
    row = rows[3]
    assert_equal 'child', row.field('parent-child')
    p_from_csv = i.find_or_create_product_from_csv(row)
    assert_equal p, p_from_csv
    
    # a subvariant row of a new product
    row = rows[17]
    assert_equal 'child', row.field('parent-child')
    parent_sku = row.field('parent-sku')
    assert_nil Product.find_by_sku(parent_sku)
    assert_nil Product.find_by_sku(row.field('sku'))
    p3_from_csv = i.find_or_create_product_from_csv(row)
    assert_equal parent_sku, p3_from_csv.sku
  end

  test "find or create variant from csv should work" do
    b = FactoryGirl.create(:brand, :name=>'2XU')
    sp = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')
    sp2 = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
    i = FactoryGirl.create(:import)
    rows = CSV.read(TEST_FILENAME, { :headers=>Import::H, :col_sep => "\t", :skip_blanks => true })
    
    # a new variant that doesn't already exist, should create product and variant as well
    row = rows[3]
    v = nil
    assert_equal 'child', row.field('parent-child')
    assert_difference('Product.count', 1) do
      assert_difference('Variant.count', 1) do
        assert_difference('SubVariant.count', 0) do  
          v = i.find_or_create_variant_from_csv(row)
        end
      end
    end
    assert_equal row.field('product-name'), v.amazon_product_name
    assert_equal v.get_clean_sku, v.sku
    assert_equal row.field('parent-sku'), v.product.sku
    
    # an identical variant that alreqdy exists
    v2 = nil  
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', 0) do
          v2 = i.find_or_create_variant_from_csv(row)
        end
      end
    end
    assert_equal v, v2 
    
    # a new variant for existing product
    row = rows[9]
    p = nil
    assert_equal 'parent', row.field('parent-child')
    assert_difference('Product.count', 1) do
      p = i.find_or_create_product_from_csv(row)
    end
    assert_equal 'SizeColor', p.variation_theme
    
    row = rows[10]
    v3 = nil
    assert_equal 'child', row.field('parent-child')
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 1) do
        assert_difference('SubVariant.count', 0) do
          v3 = i.find_or_create_variant_from_csv(row)
        end
      end
    end
    assert_equal p, v3.product
  end

  test "find or create sub_variant from csv should work" do
    b = FactoryGirl.create(:brand, :name=>'2XU')
    sp = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')
    sp2 = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
    i = FactoryGirl.create(:import)
    rows = CSV.read(TEST_FILENAME, { :headers=>Import::H, :col_sep => "\t", :skip_blanks => true })
    
    # a new subvariant that doesn't already exist, should create product and variant as well
    row = rows[3]
    sv = nil
    assert_equal 'child', row.field('parent-child')
    assert_difference('Product.count', 1) do
      assert_difference('Variant.count', 1) do
        assert_difference('SubVariant.count', 1) do  
          sv = i.find_or_create_sub_variant_from_csv(row)
        end
      end
    end
    
    # an identical subvariant that alreqdy exists
    assert_equal row.field('product-name'), sv.variant.amazon_product_name
    assert_equal row.field('sku'), sv.sku
    assert_equal sv.variant.get_clean_sku, sv.variant.sku
    assert_equal row.field('parent-sku'), sv.variant.product.sku
    
    sv2 = nil
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', 0) do
          sv2 = i.find_or_create_sub_variant_from_csv(row)
        end
      end
    end
    assert_equal sv2, sv 
    
    # a new variant and subvariant for existing product
    row = rows[9]
    p = nil
    assert_equal 'parent', row.field('parent-child')
    assert_difference('Product.count', 1) do
      p = i.find_or_create_product_from_csv(row)
    end
    assert_equal 'SizeColor', p.variation_theme
    
    row = rows[10]
    sv3 = nil
    assert_equal 'child', row.field('parent-child')
    assert_difference('Product.count', 0) do
      assert_difference('Variant.count', 1) do
        assert_difference('SubVariant.count', 1) do
          sv3 = i.find_or_create_sub_variant_from_csv(row)
        end
      end
    end
    assert_equal p, sv3.variant.product

    # an new subvariant for existing product and variant
    row = rows[11]
    sv4 = nil
    assert_equal 'child', row.field('parent-child')
    
    assert_difference('Product.count', 0) do
      #assert_difference('Variant.count', 0) do
        assert_difference('SubVariant.count', 1) do
          sv4 = i.find_or_create_sub_variant_from_csv(row)
        end
      #end
    end
    assert_equal sv3.variant, sv4.variant
    assert_equal p, sv4.variant.product
    assert_not_equal sv3.size_code, sv4.size_code
  end
  
end
