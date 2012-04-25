require 'iconv'

class Import < ActiveRecord::Base
	
  has_attached_file :input_file
  has_attached_file :error_file

  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  attr_accessible :error_file, :format, :import_date, :input_file, :status
  validates_presence_of :import_date
  
	def self.build_from_csv(parentRows,row)
		$custError = nil		     
    brand_name = row[header.index('brand')] # lookup brandId then row brand    
		isBrand = Brand.find_by_name(brand_name)
		#raise isBrand.nil?.inspect
    unless isBrand.nil?    
	 		$brandId = Brand.find_by_name(brand_name).id
	 		isSkuPattern = SkuPattern.find_by_brand_id($brandId)			 		  		  
		  unless isSkuPattern.blank?   
				if row[header.index('parent-child')] == 'parent'
					createProduct row
				else
					#raise "create subvariant"	
					createSubVariant row									
				end
			else
				isSkuPattern = SkuPattern.new
				isSkuPattern.errors[:pattern] << 'No entry for sku patters #{$brandId}.'
				$custError = "No entry for sku patters #{$brandId}."
    		return isSkuPattern, $custError		
			end	
    else
    	isBrand = Brand.new
     	isBrand.errors[:name] << 'Brand #{brand_name} does not exist.'    	
    	$custError = "Brand #{brand_name} does not exist."
    	return isBrand, $custError
    end
         
  end	
  
  def self.csv_header
    "Name,Email,Password".split(',')
  end  
  
  def self.importHeader(row)  	
  	$header = row  	
  	header
  	return header
  end
  
  def self.header   	 	
  	return $header
  end
  
  def self.createProduct(row)
  	#raise "Creating product"
  	sku = row[header.index('sku')]					
		#raise Product.find_or_initialize_by_sku(sku).blank?.inspect				
		#if Product.where(:sku => sku).blank?
		product = Product.find_or_initialize_by_sku(sku)
		#product = Product.new	  						
		#raise product.inspect										
		product.attributes = { :name => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-name')]),
			:description => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-description')]),    			
			#:deleted_at => row[header.index('deleted_at')],
			:available_on => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('release-date')]),
			#:meta_description => row[header.index('meta_description')],
			#:meta_keywords => row[header.index('meta_keywords')],
			:brand_id => $brandId,
			:sku => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sku')]),
			#:category => row[header.index('category')],
			:product_type => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('clothing-type')]),
			:variation_theme => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('variation-theme')]),
			:department => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('department1')]),
			:file_date => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('date')]),
			:amazon_template => 'clothing',
			:keywords => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('style-keyword1')]),
			:keywords2 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t")),
			:keywords3 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t"))
		}
		#raise product.inspect						
		return product, $custError			
		#else
		#raise "Product #{row}present"		
		#end
  end
  
  def self.createSubVariant(row)
  	#raise "creating subvariant"
  	sku = row[header.index('sku')].gsub(/-AZ.*$/,'')
		sku_arr = sku.split(/-/)										
		parent_sku = row[header.index('parent-sku')]					
		parent_sku_arr = parent_sku.split(/-/)					
		variation_arr = sku_arr - parent_sku_arr
		
		variation_theme = row[header.index('variation-theme')]
		
		upc = nil
		asin = nil
		
		if row[header.index('product-id-type')] == 'UPC'
			upc = Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-id')])
		elsif row[header.index('product-id-type')] == 'ASIN'
			asin = Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-id')])
		end		
		if variation_arr.size == 2					
			subVarientsp = variation_arr.pop						
			varientsp = variation_arr[0]						
			varientsku = [sku_arr[0],varientsp].join('-')						
			if Variant.find_by_sku(varientsku).blank?
				#raise "subVariant"
				#if Product.find_by_sku(sku_arr[0]).nil?
				product = Product.find_or_initialize_by_sku(sku_arr[0])														
				product.attributes = { :name => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-name')]),
					:description => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-description')]),    			
					#:deleted_at => row[header.index('deleted_at')],
					:available_on => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('release-date')]),
					#:meta_description => row[header.index('meta_description')],
					#:meta_keywords => row[header.index('meta_keywords')],
					:brand_id => $brandId,
					:sku => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sku')]),
					#:category => row[header.index('category')],
					:product_type => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('clothing-type')]),
					:variation_theme => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('variation-theme')]),
					:department => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('department1')]),
					:file_date => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('date')]),
					:amazon_template => 'clothing',
					:keywords => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('style-keyword1')]),
					:keywords2 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t")),
					:keywords3 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t"))
				}						
				#raise product.inspect								
				#end
				#raise "about to crate variant"
				#variant = Variant.new
				variant = Variant.find_or_initialize_by_sku(varientsku)
				#raise variant.inspect
				#raise row[header.index('product-id')].inspect
				variant.attributes = { :product_id => product.id,
						:sku => varientsku,
						:cost_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('item-price')]),
						:currency => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('currency')]),
						:msrp => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('msrp')]),
						:sale_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sale-price')]),
						:leadtime_to_ship => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('leadtime-to-ship')]),
						:upc => upc,
						:asin => asin
				}
				#raise "variant"
				#return variant
				#raise variant.inspect
				#subvarient = SubVariant.new
				subvarient = SubVariant.find_or_initialize_by_sku(sku)
				#raise row[header.index('sku')].inspect							
				subvarient.attributes = { :variant_id => variant.id,
						:sku => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sku')]),
						:upc => upc,
						:asin => asin
				}
				#raise subvarient.inspect
				#raise product.inspect
				#raise variant.inspect
				#raise subvarient.inspect
				return product, $custError, variant, subvarient
				#raise "creating subvariant"
			else
				#raise "Variant Present"
				createVariant row
			end
		else
			raise "variant"
			createVariant row															
		end
  end
  
  def self.createVariant(row)
  	sku = row[header.index('sku')].gsub(/-AZ.*$/,'')
		sku_arr = sku.split(/-/)										
		parent_sku = row[header.index('parent-sku')]					
		parent_sku_arr = parent_sku.split(/-/)					
		variation_arr = sku_arr - parent_sku_arr
		
		variation_theme = row[header.index('variation-theme')]
		
		upc = nil
		asin = nil
		
		if row[header.index('product-id-type')] == 'UPC'
			upc = Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-id')])
		elsif row[header.index('product-id-type')] == 'ASIN'
			asin = Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-id')])
		end
		subVarientsp = variation_arr.pop						
		varientsp = variation_arr[0]						
		varientsku = [sku_arr[0],varientsp].join('-')
		#raise sku_arr[0].inspect
		if Variant.find_by_sku(sku).blank?
			#raise parent_sku.inspect
			#if Product.find_by_sku(parent_sku).nil?
			#product = Product.new	 
			product = Product.find_or_initialize_by_sku(sku_arr[0])
			#raise product.inspect 						
			product.attributes = { :name => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-name')]),
				:description => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('product-description')]),    			
				#:deleted_at => row[header.index('deleted_at')],
				:available_on => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('release-date')]),
				#:meta_description => row[header.index('meta_description')],
				#:meta_keywords => row[header.index('meta_keywords')],
				:brand_id => $brandId,
				:sku => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sku')]),
				#:category => row[header.index('category')],
				:product_type => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('clothing-type')]),
				:variation_theme => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('variation-theme')]),
				:department => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('department1')]),
				:file_date => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('date')]),
				:amazon_template => 'clothing',
				:keywords => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('style-keyword1')]),
				:keywords2 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t")),
				:keywords3 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t"))
			}						
			#raise product.inspect								
			#end
			#raise "about to crate variant"
			#raise "about to crate variant"
			#variant = Variant.new
			variant = Variant.find_or_initialize_by_sku(varientsku)
			#raise variant.inspect
			#raise row[header.index('product-id')].inspect
			variant.attributes = { :product_id => product.id,
					:sku => varientsku,
					:cost_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('item-price')]),
					:currency => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('currency')]),
					:msrp => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('msrp')]),
					:sale_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sale-price')]),
					:leadtime_to_ship => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('leadtime-to-ship')]),
					:upc => upc,
					:asin => asin
			}
			#raise product.inspect
			#raise variant.inspect
			return product, $custError , variant
		else
			raise "subvariant"
			createSubVariant row
		end	
  end
end
