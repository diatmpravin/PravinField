# encoding: utf-8

class Import < ActiveRecord::Base
  attr_accessible :error_file, :format, :import_date, :input_file, :status
  attr_accessor :product_count, :variant_count, :sub_variant_count
  has_attached_file :input_file, PAPERCLIP_STORAGE_OPTIONS
  has_attached_file :error_file, PAPERCLIP_STORAGE_OPTIONS.merge({:default_url=>''})
  
  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  validates_presence_of :import_date
  after_initialize :init_counters
  
  AMZ_H = %w(TemplateType=Clothing	Version=1.4	This row for Amazon.com use only.  Do not modify or delete.							Macros:																																																																													)
  H = %w(sku	product-id	product-id-type	product-name	brand	bullet-point1	bullet-point2	bullet-point3	bullet-point4	bullet-point5	product-description	clothing-type	size	size-modifier	color	color-map	material-fabric1	material-fabric2	material-fabric3	department1	department2	department3	department4	department5	style-keyword1	style-keyword2	style-keyword3	style-keyword4	style-keyword5	occasion-lifestyle1	occasion-lifestyle2	occasion-lifestyle3	occasion-lifestyle4	occasion-lifestyle5	search-terms1	search-terms2	search-terms3	search-terms4	search-terms5	size-map	waist-size-unit-of-measure	waist-size	inseam-length-unit-of-measure	inseam-length	sleeve-length-unit-of-measure	sleeve-length	neck-size-unit-of-measure	neck-size	chest-size-unit-of-measure	chest-size	cup-size	shoe-width	parent-child	parent-sku	relationship-type	variation-theme	main-image-url	swatch-image-url	other-image-url1	other-image-url2	other-image-url3	other-image-url4	other-image-url5	other-image-url6	other-image-url7	other-image-url8	shipping-weight-unit-measure	shipping-weight	product-tax-code	launch-date	release-date	msrp	item-price	sale-price	currency	fulfillment-center-id	sale-from-date	sale-through-date	quantity	leadtime-to-ship	restock-date	max-aggregate-ship-quantity	is-gift-message-available	is-gift-wrap-available	is-discontinued-by-manufacturer	registered-parameter	update-delete)
  HEADER_ROWS = 2
  VARIATION_THEMES = %w(Size Color SizeColor)
  PARENT_CHILD = %w(parent child)
  CSV_DELIMITER = "\t"
  KEYWORD_DELIMITER = "\r"
  
  def process_input_file  	  	  			  		
    errs = []
    self.format = 'csv'
    if self.import_date.nil?
      self.import_date = Time.now
    end

    i=0
    CSV.foreach(self.input_file.path, { :headers=>H, :col_sep => CSV_DELIMITER, :skip_blanks => true }) do |row|
      i+=1      
      #begin
    	  if row.field('parent-child') == 'parent'  
          self.find_or_create_product_from_csv(row)
  		  elsif row.field('parent-child') == 'child'	
  			  self.find_or_create_sub_variant_from_csv(row)
        elsif i>HEADER_ROWS
          raise "Missing Parent-Child Designation"      
  		  end
      #rescue Exception
    	  row.push $!
        errs << row
      #end
    end
    
    self.status = "#{self.product_count} products, #{self.variant_count} variants, #{self.sub_variant_count} sub_variants, #{errs.length} errors"
    self.save
    
    #Export Error file for later upload upon correction
    if errs.any?
			errs.unshift H+['Error'] # Add a header row
			errs.unshift AMZ_H      # Add Amazon template row
			
			self.error_file = Paperclip::Tempfile.new("errors_#{Date.today.strftime('%Y%m%d')}.csv")
      self.save
      CSV.open(self.error_file.path, "wb", { :col_sep => CSV_DELIMITER }) do |csv|
        errs.each {|row| csv << row }
      end
    end
  end
  
  def find_or_create_product_from_csv(r)
    brand = Brand.find_by_name(r.field('brand'))
    raise "Brand does not exist" if brand.nil?
		raise "Missing SubVariant SKU pattern" if SkuPattern.find_by_brand_id_and_granularity(brand.id, 'SubVariant').nil?		
		raise "Missing Variant SKU pattern" if SkuPattern.find_by_brand_id_and_granularity(brand.id, 'Variant').nil?
    raise "Missing Variation Theme" if !VARIATION_THEMES.include?(r.field('variation-theme'))
    raise "Missing Parent SKU" if (r.field('parent-child')=='child' && r.field('parent-sku').nil?)
    
    product_sku = r.field('parent-sku') ? r.field('parent-sku') : r.field('sku')
    p = Product.find_by_sku(product_sku)
    if p.nil?
      p = Product.new(:sku=>product_sku)
      self.product_count += 1      
    end
    p.update_attributes(
		  :name => r.field('product-name'),
			:description => r.field('product-description'),
			:available_on => r.field('release-date'),
			#:meta_description => r.field('meta_description'),
			#:meta_keywords => r.field('meta_keywords'),
			:brand_id => brand.id,
			:product_type => r.field('clothing-type'),
			:variation_theme => r.field('variation-theme'),
			:department => [r.field('department1'),r.field('department2'),
			                r.field('department3'),r.field('department4'),
			                r.field('department5')].compact.join(KEYWORD_DELIMITER),
			:amazon_template => 'Clothing',
			:style_keywords =>
			  [r.field('style-keyword1'), r.field('style-keyword2'), 
			  r.field('style-keyword3'), r.field('style-keyword4'), 
			  r.field('style-keyword5')].compact.join(KEYWORD_DELIMITER),
			:occasion_lifestyle_keywords => 
			  [r.field('occasion-lifestyle1'), r.field('occasion-lifestyle2'),
			  r.field('occasion-lifestyle3'), r.field('occasion-lifestyle4'),
			  r.field('occasion-lifestyle5')].compact.join(KEYWORD_DELIMITER),
			:search_keywords => 
			  [r.field('search-terms1'), r.field('search-terms2'),
			  r.field('search-terms3'), r.field('search-terms4'),
			  r.field('search-terms5')].compact.join(KEYWORD_DELIMITER),
			:bullet_points =>
		    [r.field('bullet_point1'), r.field('bullet_point2'),
		    r.field('bullet_point3'), r.field('bullet_point4'),
		    r.field('bullet_point5')].compact.join(KEYWORD_DELIMITER)
		)
		return p
  end

  def find_or_create_variant_from_csv(r)  	
		p = self.find_or_create_product_from_csv(r)	
		h = SkuPattern.parse_variant(p.brand, r.field('sku'), r.field('parent-sku'))
    variant = Variant.find_by_product_id_and_sku(p.id, h[:variant_sku])
    if variant.nil?
      variant = Variant.new(:product_id=>p.id, :sku=>h[:variant_sku])
		  self.variant_count += 1      
    end
    		
    #TODO what to do about update-delete field
		#TODO variant image
		#TODO check if data is newer or older
		variant.update_attributes(
			#:cost_price => r.field('item-price'),
			#:size => r.field('size'),
			:amazon_product_name => r.field('product-name'), #TODO save all other variant detail
			:color1 => r.field('color'),
			:color1_code => h[:color1_code],
			:color2_code => h[:color2_code],
			:price => r.field('item-price'),
			:sale_price => r.field('sale-price'), #TODO save item-price
			:msrp => r.field('msrp'),
			:currency => r.field('currency')
			#:leadtime_to_ship => r.field('leadtime-to-ship')
		)
		vI = self.find_or_create_variant_image(variant.id,r)		
		return variant
  end

  def find_or_create_sub_variant_from_csv(r)    
		v = self.find_or_create_variant_from_csv(r)
    sku_hash = SkuPattern.parse(v.product.brand, r.field('sku'), r.field('parent-sku'))
		sub_variant_sku = SkuPattern.strip_amazon_suffix(r.field('sku'))
		sub_variant = SubVariant.find_by_sku(sub_variant_sku)
		if sub_variant.nil?
		  sub_variant = SubVariant.new(:sku=>sub_variant_sku)
  		self.sub_variant_count += 1
		end
		sub_variant.update_attributes(
		  :variant_id => v.id,
			:size => r.field('size'),
			:upc => r.field('product-id-type')=='UPC' ? r.field('product-id') : nil,
			:asin => r.field('product-id-type')=='ASIN' ? r.field('product-id') : nil,
			:quantity => r.field('quantity'),
			:fulfillment_latency => r.field('leadtime-to-ship'),
			:size_code => sku_hash[:size_code]
		)
		return sub_variant
  end
  
  def find_or_create_variant_image(variantId,r)  	
  	vImage = VariantImage.find_by_variant_id(variantId)  	
  	if vImage.nil?
  		variant_image = VariantImage.new(:variant_id => variantId) 
  	end  	
  	variant_image.update_attributes(
  		:variant_id => variantId,
  		:unique_image_file_name => r.field('main-image-url')
  	)
  	return variant_image
  end

  protected

  def init_counters
    self.product_count = 0
    self.variant_count = 0
    self.sub_variant_count = 0
  end  
	
end

