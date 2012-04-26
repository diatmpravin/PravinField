require 'iconv'

class Import < ActiveRecord::Base
<<<<<<< HEAD
  attr_accessible :error_file, :format, :import_date, :input_file, :status
  attr_accessor :header
  has_attached_file :input_file, PAPERCLIP_STORAGE_OPTIONS
  has_attached_file :error_file, PAPERCLIP_STORAGE_OPTIONS
  
=======
	
  has_attached_file :input_file
  has_attached_file :error_file

>>>>>>> dcb19a13100d93c3679620fa99189584b0c466d4
  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  validates_presence_of :import_date
  
<<<<<<< HEAD
  after_save :process_input_file
  
  H = %w(sku	product-id	product-id-type	product-name	brand	bullet-point1	bullet-point2	bullet-point3	bullet-point4	bullet-point5	product-description	clothing-type	size	size-modifier	color	color-map	material-fabric1	material-fabric2	material-fabric3	department1	department2	department3	department4	department5	style-keyword1	style-keyword2	style-keyword3	style-keyword4	style-keyword5	occasion-lifestyle1	occasion-lifestyle2	occasion-lifestyle3	occasion-lifestyle4	occasion-lifestyle5	search-terms1	search-terms2	search-terms3	search-terms4	search-terms5	size-map	waist-size-unit-of-measure	waist-size	inseam-length-unit-of-measure	inseam-length	sleeve-length-unit-of-measure	sleeve-length	neck-size-unit-of-measure	neck-size	chest-size-unit-of-measure	chest-size	cup-size	shoe-width	parent-child	parent-sku	relationship-type	variation-theme	main-image-url	swatch-image-url	other-image-url1	other-image-url2	other-image-url3	other-image-url4	other-image-url5	other-image-url6	other-image-url7	other-image-url8	shipping-weight-unit-measure	shipping-weight	product-tax-code	launch-date	release-date	msrp	item-price	sale-price	currency	fulfillment-center-id	sale-from-date	sale-through-date	quantity	leadtime-to-ship	restock-date	max-aggregate-ship-quantity	is-gift-message-available	is-gift-wrap-available	is-discontinued-by-manufacturer	registered-parameter	update-delete)
  
  def process_input_file 		  		
    errs = []
    i = 0
    CSV.foreach(self.input_file.path, { :headers=>H, :col_sep => "\t", :skip_blanks => true }) do |row|
      i+=1
      if i>2
        puts row.inspect
        @importproduct = Import.build_from_csv(row) # build_from_csv method will map customer attributes & build new customer record
        #raise @importproduct.inspect
        next if !@importproduct.blank?              
        if @importproduct.valid? # Save upon valid otherwise collect error records to export
          #raise "valid"
          @importproduct.save
          raise "Maisa"
        else
      	  raise "invalid"        	
      	  row.push @importproduct.errors.full_messages.join(',')
          errs << row
        end
      end
    end
    
     #Export Error file for later upload upon correction
    if errs.any?      	
      errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
      errs.insert(0, Import.csv_header)
      errCSV = CSV.generate do |csv|
        errs.each {|row| csv << row}
      end
      
			file = Paperclip::Tempfile.new(errFile)
			errCSV.write(file.path)
			#vi.image_content_type = combo_img.mime_type
			#vi.image_file_size = combo_img.filesize
			#vi.image_width = combo_img.columns
			self.error_file = file
      #send_data errCSV, :type => 'text/csv; charset=iso-8859-1; header=present',:disposition => "attachment; filename=#{errFile}.csv"
    end
  end
  
	def self.build_from_csv(row)
    b = Brand.find_by_name(row.field('brand')) 
	 	unless b.nil?
		  unless SkuPattern.find_by_brand_id(b.id).nil?
				if row.field('parent-child') == 'parent'
					sku = row.field('sku')					
					#raise Product.find_or_initialize_by_sku(sku).blank?.inspect				
					if Product.where(:sku => sku).blank?
						return Product.new(						
						  :name => row.field('product-name'),
							:description => row.field('product-description'),
							#:deleted_at => row.field('deleted_at'),
							#:available_on => row.field('release-date'),
							#:meta_description => row.field('meta_description'),
							#:meta_keywords => row.field('meta_keywords'),
							:brand_id => b.id,
							:sku => sku,
							#:category => row.field('category'),
							:product_type => row.field('clothing-type'),
							:variation_theme => row.field('variation-theme'),
							:department => row.field('department1'),
							#:file_date => )('date'),
							:amazon_template => 'Clothing',
							:keywords => row.field('style-keyword1'),
							:keywords2 => [row.field('occasion-lifestyle1'),row.field('occasion-lifestyle2'),row.field('occasion-lifestyle3'),row.field('occasion-lifestyle4'),row.field('occasion-lifestyle5')].join("\t"),
							:keywords3 => [row.field('search-terms1'), row.field('search-terms2'),row.field('search-terms3'),row.field('search-terms4'),row.field('search-terms5')].join("\t")
						)
					else
							
					end
					
				else				
					sku = row.field('sku').gsub(/-AZ.*$/,'')
					sku_arr = sku.split(/-/)										
					parent_sku = row.field('parent-sku')					
					parent_sku_arr = parent_sku.split(/-/)					
					variation_arr = sku_arr - parent_sku_arr
					
					variation_theme = row.field('variation-theme')
					
					upc = nil
					asin = nil
					
					if row.field('product-id-type') == 'UPC'
						upc = row.field('product-id')
					elsif row.field('product-id-type') == 'ASIN'
						asin = row.field('product-id')
					end
					
					if variation_arr.size == 2						
						subVariantsp = variation_arr.pop						
						variantsp = variation_arr[0]						
						variantsku = [sku_arr[0],variantsp].join('-')						
						if Variant.find_by_sku(variantsku).blank?
							if Product.find_by_sku(sku_arr[0]).nil?
								product = Product.new	  						
								product.attributes = { :name => row.field('product-name'),
									:description => row.field('product-description'),    			
									#:deleted_at => row.field('deleted_at'),
									:available_on => row.field('release-date'),
									#:meta_description => row.field('meta_description'),
									#:meta_keywords => row.field('meta_keywords'),
									:brand_id => $brandId,
									:sku => row.field('sku'),
									#:category => row.field('category'),
									:product_type => row.field('clothing-type'),
									:variation_theme => row.field('variation-theme'),
									:department => row.field('department1'),
									:file_date => row.field('date'),
									:amazon_template => 'Clothing',
									:keywords => row.field('style-keyword1'),
									:keywords2 => [row.field('occasion-lifestyle1'),row.field('occasion-lifestyle2'),row.field('occasion-lifestyle3'),row.field('occasion-lifestyle4'),row.field('occasion-lifestyle5')].join("\t"),
									:keywords3 => [row.field('search-terms1'),row.field('search-terms2'),row.field('search-terms3'),row.field('search-terms4'),row.field('search-terms5')].join("\t")
								}						
								#raise product.inspect								
							end
							#raise "about to crate variant"
							variant = Variant.new
							#raise variant.inspect
							#raise row.field('product-id').inspect
							variant.attributes = { :product_id => row.field('product-id'),
									:sku => variantsku,
									:cost_price => row.field('item-price'),
									:currency => row.field('currency'),
									:msrp => row.field('msrp'),
									:sale_price => row.field('sale-price'),
									:leadtime_to_ship => row.field('leadtime-to-ship'),
									:upc => upc,
									:asin => asin
							}
							#raise variant.inspect
							subvariant = SubVariant.new
							#raise row.field('sku').inspect							
							subvariant.attributes = { #:variant_id => row.field('variant-id'),
									:sku => row.field('sku'),
									:upc => upc,
									:asin => asin
							}
							return product
							raise "creating subvariant"
						else
							raise "Variant Present"
						end
					else												
						if Variant.find_by_sku(sku).blank?
							#raise parent_sku.inspect
							if Product.find_by_sku(parent_sku).nil?
								product = Product.new	  						
								product.attributes = { :name => row.field('product-name'),
									:description => row.field('product-description'),    			
									#:deleted_at => row.field('deleted_at'),
									:available_on => row.field('release-date'),
									#:meta_description => row.field('meta_description'),
									#:meta_keywords => row.field('meta_keywords'),
									:brand_id => $brandId,
									:sku => parent_sku,
									#:category => row.field('category'),
									:product_type => row.field('clothing-type'),
									:variation_theme => row.field('variation-theme'),
									:department => row.field('department1'),
									:file_date => row.field('date'),
									:amazon_template => 'Clothing',
									:keywords => row.field('style-keyword1'),
									:keywords2 => [row.field('occasion-lifestyle1'),row.field('occasion-lifestyle2'),row.field('occasion-lifestyle3'),row.field('occasion-lifestyle4'),row.field('occasion-lifestyle5')].join("\t"),
									:keywords3 => [row.field('search-terms1'),row.field('search-terms2'),row.field('search-terms3'),row.field('search-terms4'),row.field('search-terms5')].join("\t")
								}						
								#raise product.inspect								
							end
							#raise "about to crate variant"
							#raise "about to crate variant"
							variant = Variant.new
							#raise variant.inspect
							#raise row.field('product-id').inspect
							variant.attributes = { :product_id => row.field('product-id'),
									:sku => sku,
									:cost_price => row.field('item-price'),
									:currency => row.field('currency'),
									:msrp => row.field('msrp'),
									:sale_price => row.field('sale-price'),
									:leadtime_to_ship => row.field('leadtime-to-ship'),
									:upc => upc,
									:asin => asin
							}
							raise variant.inspect
=======
	def self.build_from_csv(row)
		$custError = nil		     
    brand_name = row[header.index('brand')] # lookup brandId then row brand 
    $parent_sku = row[header.index('parent-sku')]					
		$variation_theme = row[header.index('variation-theme')]   
		isBrand = Brand.find_by_name(brand_name)		
    product = Product.new
    unless isBrand.nil?    
	 		$brandId = Brand.find_by_name(brand_name).id
	 		$isSkuPattern = SkuPattern.find_by_brand_id($brandId)			 		  		  
		  unless $isSkuPattern.blank?   
				if row[header.index('parent-child')] == 'parent'
					createProduct row
				else	
					if !$parent_sku.nil? && !$variation_theme.nil?
						$upc = nil
						$asin = nil
						if row[header.index('product-id-type')] == 'UPC'
							$upc = Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-id')])
						elsif row[header.index('product-id-type')] == 'ASIN'
							$asin = Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-id')])
						end
						if $variation_theme == "SizeColor" || $variation_theme == "Size"
							createSubVariant row
>>>>>>> dcb19a13100d93c3679620fa99189584b0c466d4
						else
							createVariant row							
						end
<<<<<<< HEAD
						raise "Maisa"
					end
					
					if !parent_sku.nil? && !variation_theme.nil?
						#raise "not nil"
						#begin														
							if Product.where(:sku => sku).blank?
								varientProduct = Product.new
								if variation_theme == 'SizeColor' || variation_theme == 'color'
									#raise row.field('color').inspect
									if variation_theme == 'SizeColor'
										size_code = variation_arr.pop
										#raise size_code.inspect
										sku_arr.pop
									else
										varientProduct[:upc] = upc
										varientProduct[:asin] = asin
									end
									raise "In Progress"
									#varientProduct.attributes{
									
								#}
								else
									raise "sub varient"
								end
						
							else
							end		
						#rescue
							
						#end
					else
						raise "Bad row entry"
					end
					
					raise "Maisa"
=======
					else						
     				product.errors.add(:brand_id, "Not vaild")
						$custError = "This row have not parentSku OR variant theme."
    				return product, $custError			
					end																							
>>>>>>> dcb19a13100d93c3679620fa99189584b0c466d4
				end
			else				
     		product.errors.add(:brand_id, "Not vaild")
				$custError = "No entry for sku patters #{brand_name}."
    		return product, $custError		
			end	
    else    	
     	product.errors.add(:brand_id, "Not vaild")     	    	
    	$custError = "Brand #{brand_name} does not exist."
    	return product, $custError
    end
         
  end	
  
  def self.csv_header
    "Name,Email,Password".split(',')
  end  
  
  def self.importHeader(row)  	
  	$header = row
  	return header
  end
  
  def self.header   	 	
  	return $header
  end
  
  def self.createProduct(row)  	
  	sku = row[header.index('sku')]							
		product = Product.find_or_initialize_by_sku(sku)												
		product.attributes = { :name => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-name')]),
			:description => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-description')]),		
			:available_on => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('release-date')]),
			#:meta_description => row[header.index('meta_description')],
			#:meta_keywords => row[header.index('meta_keywords')],
			:brand_id => $brandId,
			:sku => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sku')]),
			#:category => row[header.index('category')],
			:product_type => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('clothing-type')]),
			:variation_theme => $variation_theme,
			:department => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('department1')]),
			:file_date => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('date')]),
			#:amazon_template => 'clothing',
			:keywords => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('style-keyword1')]),
			:keywords2 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t")),
			:keywords3 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t"))
		}			
		return product, $custError					
  end
  
  def self.createSubVariant(row)  	
  	sku = row[header.index('sku')].gsub(/-AZ.*$/,'')  	
		sku_arr = sku.split(/#{$isSkuPattern.delimiter}/)																	
		parent_sku_arr = $parent_sku.split(/#{$isSkuPattern.delimiter}/)					
		variation_arr = sku_arr - parent_sku_arr								
		subVariantsp = variation_arr.pop						
		variantsp = variation_arr[0]								
		variantsku = [sku_arr[0],variantsp].join($isSkuPattern.delimiter)												
		product = Product.find_or_initialize_by_sku(sku_arr[0])														
		product.attributes = { :name => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-name')]),
			:description => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-description')]),
			:available_on => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('release-date')]),
			#:meta_description => row[header.index('meta_description')],
			#:meta_keywords => row[header.index('meta_keywords')],
			:brand_id => $brandId,
			:sku => sku_arr[0],
			#:category => row[header.index('category')],
			:product_type => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('clothing-type')]),
			:variation_theme => $variation_theme,
			:department => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('department1')]),
			:file_date => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('date')]),
			#:amazon_template => 'clothing',
			:keywords => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('style-keyword1')]),
			:keywords2 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t")),
			:keywords3 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t"))
		}										
		variant = Variant.find_or_initialize_by_sku(variantsku)				
		variant.attributes = { :product_id => product.id,
				:sku => variantsku,
				:cost_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('item-price')]),
				:size => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('size')]),
				:color1 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('color')]),
				:color1_code => variantsp,
				:upc => $upc,						
				:sale_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sale-price')]),
				:msrp => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('msrp')]),
				:currency => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('currency')]),
				:leadtime_to_ship => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('leadtime-to-ship')]),						
				:asin => $asin
		}				
		subvariant = SubVariant.find_or_initialize_by_sku(sku)											
		subvariant.attributes = { :variant_id => variant.id,
				:sku => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sku')]),
				:size => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('size')]),
				:upc => $upc,
				:asin => $asin,
				:size_code => subVariantsp 
		}				
		return product, $custError, variant, subvariant
  end
  
  def self.createVariant(row)
		sku = row[header.index('sku')].gsub(/-AZ.*$/,'')  	
		sku_arr = sku.split(/#{$isSkuPattern.delimiter}/)																	
		parent_sku_arr = $parent_sku.split(/#{$isSkuPattern.delimiter}/)					
		variation_arr = sku_arr - parent_sku_arr						
		subVariantsp = variation_arr.pop						
		variantsp = variation_arr[0]						
		variantsku = [sku_arr[0],variantsp].join($isSkuPattern.delimiter)	
						 
		product = Product.find_or_initialize_by_sku(sku_arr[0])				
		product.attributes = { :name => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-name')]),
			:description => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-description')]),
			:available_on => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('release-date')]),
			#:meta_description => row[header.index('meta_description')],
			#:meta_keywords => row[header.index('meta_keywords')],
			:brand_id => $brandId,
			:sku => sku_arr[0],
			#:category => row[header.index('category')],
			:product_type => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('clothing-type')]),
			:variation_theme => $variation_theme,
			:department => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('department1')]),
			:file_date => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('date')]),
			#:amazon_template => 'clothing',
			:keywords => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('style-keyword1')]),
			:keywords2 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t")),
			:keywords3 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t"))
		}									
		variant = Variant.find_or_initialize_by_sku(variantsku)			
		variant.attributes = { :product_id => product.id,
				:sku => variantsku,
				:cost_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('item-price')]),
				:size => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('size')]),
				:color1 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('color')]),
				:color1_code => variantsp,
				:upc => $upc,						
				:sale_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sale-price')]),
				:msrp => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('msrp')]),
				:currency => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('currency')]),
				:leadtime_to_ship => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('leadtime-to-ship')]),						
				:asin => $asin
		}			
		return product, $custError , variant	
  end
end
