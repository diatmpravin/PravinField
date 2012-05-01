require 'spec_helper'

describe Import do
	
	TEST_FILENAME = 'test/fixtures/csv/2XU.txt'
	ERROR_FILENAME = 'test/fixtures/csv/2XU_errors.txt'
		
	before :all do
		HEADER_ROWS = 2
		VARIATION_THEMES = %w(Size Color SizeColor)
  	PARENT_CHILD = %w(parent child)
  	CSV_DELIMITER = "\t"
  	AMZ_H = %w(TemplateType=Clothing	Version=1.4	This row for Amazon.com use only.  Do not modify or delete.							Macros:																																																																													)
  	H = %w(sku	product-id	product-id-type	product-name	brand	bullet-point1	bullet-point2	bullet-point3	bullet-point4	bullet-point5	product-description	clothing-type	size	size-modifier	color	color-map	material-fabric1	material-fabric2	material-fabric3	department1	department2	department3	department4	department5	style-keyword1	style-keyword2	style-keyword3	style-keyword4	style-keyword5	occasion-lifestyle1	occasion-lifestyle2	occasion-lifestyle3	occasion-lifestyle4	occasion-lifestyle5	search-terms1	search-terms2	search-terms3	search-terms4	search-terms5	size-map	waist-size-unit-of-measure	waist-size	inseam-length-unit-of-measure	inseam-length	sleeve-length-unit-of-measure	sleeve-length	neck-size-unit-of-measure	neck-size	chest-size-unit-of-measure	chest-size	cup-size	shoe-width	parent-child	parent-sku	relationship-type	variation-theme	main-image-url	swatch-image-url	other-image-url1	other-image-url2	other-image-url3	other-image-url4	other-image-url5	other-image-url6	other-image-url7	other-image-url8	shipping-weight-unit-measure	shipping-weight	product-tax-code	launch-date	release-date	msrp	item-price	sale-price	currency	fulfillment-center-id	sale-from-date	sale-through-date	quantity	leadtime-to-ship	restock-date	max-aggregate-ship-quantity	is-gift-message-available	is-gift-wrap-available	is-discontinued-by-manufacturer	registered-parameter	update-delete)  	
	end
 	
 	describe "validation" do
  	it "should not be valid without a import_date" do
  		aImport = Import.create(:import_date => "")
  		aImport.should_not be_valid
  	end
  	
  	it "should not be valid without a import_date" do
  		aImport = Import.create(:import_date => "")
  		aImport.valid?.should == false
  	end
  	
  	it "should save when import_date is not empty" do
  		Import.new(:import_date =>DateTime.now ).save.should == true
  	end
  end
  
  describe "Associations" do
  	it "has many variant_updates" do
  		Import.new.should respond_to(:variant_updates)
  	end
  end
  
  describe "variable assignment" do
  	context "When valid" do
			it "should have HEADER_ROWS '2'" do
				HEADER_ROWS.should == 2  		
			end
			
			it "should have VARIATION_THEMES 'Size Color SizeColor'" do  		
				VARIATION_THEMES.should == %w(Size Color SizeColor)  		  		
			end
			
			it "should have parent_child 'parent child'" do  		  		
				PARENT_CHILD.should == %w(parent child)
			end
			
			it "should have valid CSV_DELIMITER tab" do  		  		
				CSV_DELIMITER.should == "\t"  		
			end
			
			it "should have valid AMAZOM_H" do
				AMZ_H.should == %w(TemplateType=Clothing	Version=1.4	This row for Amazon.com use only.  Do not modify or delete.							Macros:																																																																													)	
			end
			
			it "should have valid HEADER" do 
				H.should == %w(sku	product-id	product-id-type	product-name	brand	bullet-point1	bullet-point2	bullet-point3	bullet-point4	bullet-point5	product-description	clothing-type	size	size-modifier	color	color-map	material-fabric1	material-fabric2	material-fabric3	department1	department2	department3	department4	department5	style-keyword1	style-keyword2	style-keyword3	style-keyword4	style-keyword5	occasion-lifestyle1	occasion-lifestyle2	occasion-lifestyle3	occasion-lifestyle4	occasion-lifestyle5	search-terms1	search-terms2	search-terms3	search-terms4	search-terms5	size-map	waist-size-unit-of-measure	waist-size	inseam-length-unit-of-measure	inseam-length	sleeve-length-unit-of-measure	sleeve-length	neck-size-unit-of-measure	neck-size	chest-size-unit-of-measure	chest-size	cup-size	shoe-width	parent-child	parent-sku	relationship-type	variation-theme	main-image-url	swatch-image-url	other-image-url1	other-image-url2	other-image-url3	other-image-url4	other-image-url5	other-image-url6	other-image-url7	other-image-url8	shipping-weight-unit-measure	shipping-weight	product-tax-code	launch-date	release-date	msrp	item-price	sale-price	currency	fulfillment-center-id	sale-from-date	sale-through-date	quantity	leadtime-to-ship	restock-date	max-aggregate-ship-quantity	is-gift-message-available	is-gift-wrap-available	is-discontinued-by-manufacturer	registered-parameter	update-delete)
			end
		end

  end
  
  describe "methods test" do
  	context "init_counters method's' variables" do
			it "iniliatize as 0 is valid" do
				subject { Import.init_counters()}
				subject.product_count.should == 0
				subject.variant_count.should == 0
				subject.sub_variant_count.should == 0
			end
			
			it "iniliatize as 5 is invalid" do
				subject { Import.init_counters()}
				subject.product_count.should_not == 5
				subject.variant_count.should_not == 5
				subject.sub_variant_count.should_not == 5
			end
		end
		
		context "init_counters method's' variables" do
			it "iniliatize as 0 is valid" do
				subject { Import.init_counters()}
				subject.product_count.should == 0
				subject.variant_count.should == 0
				subject.sub_variant_count.should == 0
			end
			
			it "iniliatize as 5 is invalid" do
				subject { Import.init_counters()}
				subject.product_count.should_not == 5
				subject.variant_count.should_not == 5
				subject.sub_variant_count.should_not == 5
			end
		end
  end
  
  describe "Process input file" do
  	
  	before :each do
			@header_rows = 2
  		@product_rows = 3
  		@variant_rows = 4
  		@valid_sub_variant_rows = 22
  		@error_sub_variant_rows = 2
      @total_rows = @product_rows + @valid_sub_variant_rows + @error_sub_variant_rows
		end
  		
  	context "when sucessful" do
  		it "should have total lines" do  			
  			aRead = File.open(TEST_FILENAME).readlines.size
  			aRead.should == @total_rows+@header_rows
  		end
  		
  		it "should get a brand error missing on every row" do   		   		
  			aProduct = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))  			
  			aProduct.process_input_file
  			aErrorFile = File.open(aProduct.error_file.path).readlines
  			aProduct.status.should == "0 products, 0 variants, 0 sub_variants, #{@total_rows} errors"
  		end
  		
  		it "should get a sub_sku patterns missing error on every row" do   		   		
  			aBrand = FactoryGirl.create(:brand, :name =>'2XU')
  			aProduct = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))  			
  			aProduct.process_input_file
  			aErrorFile = File.open(aProduct.error_file.path).readlines  			
  			aProduct.status.should == "0 products, 0 variants, 0 sub_variants, #{@total_rows} errors"
  		end
  		
  		it "should get a sku patterns error on every row" do   		   		
  			aBrand = FactoryGirl.create(:brand, :name =>'2XU')
  			aSkuPattern = FactoryGirl.create(:sku_pattern, :brand_id=>aBrand.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
  			aProduct = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))  			
  			aProduct.process_input_file
  			aErrorFile = File.open(aProduct.error_file.path).readlines  			
  			aProduct.status.should == "0 products, 0 variants, 0 sub_variants, #{@total_rows} errors"
  		end
  		
  		it "should create product,variant and subvariant row" do   		   		
  			aBrand = FactoryGirl.create(:brand, :name =>'2XU')
  			aSubSkuPattern = FactoryGirl.create(:sku_pattern, :brand_id=>aBrand.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
  			aSkuPattern = FactoryGirl.create(:sku_pattern, :brand_id=>aBrand.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')
  			aProduct = FactoryGirl.create(:import, :input_file => File.new(TEST_FILENAME))  			
  			aProduct.process_input_file
  			aErrorFile = File.open(aProduct.error_file.path).readlines  			
  			aProduct.status.should == "#{@product_rows} products, #{@variant_rows} variants, #{@valid_sub_variant_rows} sub_variants, #{@error_sub_variant_rows} errors"
  		end
  		
  		it "should create 2 subvariant row" do
  			pending
  			aProduct = FactoryGirl.create(:import, :input_file => File.new(ERROR_FILENAME))  			
  			aProduct.process_input_file  			
  			aErrorFile = File.open(aProduct.error_file.path).readlines  				
  			aProduct.status.should == "0 products, 0 variants, #{@error_sub_variant_rows} sub_variants, 0 errors"
  		end
  		
  	end
  	
  end	
  
  describe "Create variant image" do 
  	context "successful" do
  		it "should create new variant image" do 
				aBrand = FactoryGirl.create(:brand, :name=>'2XU')
				aSkuPattern = FactoryGirl.create(:sku_pattern, :brand_id=>aBrand.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')
				aSubSkuPattern = FactoryGirl.create(:sku_pattern, :brand_id=>aBrand.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
				aImport = FactoryGirl.create(:import)
				rows = CSV.read(TEST_FILENAME, { :headers=>Import::H, :col_sep => Import::CSV_DELIMITER, :skip_blanks => true })
				
				row = rows[3]
				if row.field('parent-child') == "child"
					aVariant = aImport.find_or_create_variant_from_csv(row)					
					someVariantImages = aImport.find_or_create_variant_images_from_csv(aVariant.id,row)
					someVariantImages[0].unique_image_file_name.should == row.field('main-image-url')
					someVariantImages[0].variant_id.should == aVariant.id
				end
			end
	  end

  end

end
