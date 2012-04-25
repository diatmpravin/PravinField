require 'iconv'

class Import < ActiveRecord::Base
	
  has_attached_file :input_file
  has_attached_file :error_file

  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  attr_accessible :error_file, :format, :import_date, :input_file, :status
  validates_presence_of :import_date
  
	def self.build_from_csv(row)
		$custError = nil		     
    brand_name = row[header.index('brand')] # lookup brandId then row brand 
    $parent_sku = row[header.index('parent-sku')]					
		$variation_theme = row[header.index('variation-theme')]   
		isBrand = Brand.find_by_name(brand_name)		
    unless isBrand.nil?    
	 		$brandId = Brand.find_by_name(brand_name).id
	 		isSkuPattern = SkuPattern.find_by_brand_id($brandId)			 		  		  
		  unless isSkuPattern.blank?   
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
						else
							createVariant row							
						end
					else
						isProduct = Product.new
						isProduct.errors[:brand] << 'This row have not parentSku OR variant theme.'
						$custError = "This row have not parentSku OR variant theme."
    				return isSkuPattern, $custError			
					end																							
				end
			else
				isSkuPattern = SkuPattern.new
				isSkuPattern.errors[:pattern] << 'No entry for sku patters #{brand_name}.'
				$custError = "No entry for sku patters #{brand_name}."
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
		sku_arr = sku.split(/-/)																	
		parent_sku_arr = $parent_sku.split(/-/)					
		variation_arr = sku_arr - parent_sku_arr
		
		if variation_arr.size == 2					
			subVariantsp = variation_arr.pop						
			variantsp = variation_arr[0]						
			variantsku = [sku_arr[0],variantsp].join('-')						
			if Variant.find_by_sku(variantsku).blank?				
				product = Product.find_or_initialize_by_sku(sku_arr[0])														
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
				variant = Variant.find_or_initialize_by_sku(variantsku)				
				variant.attributes = { :product_id => product.id,
						:sku => variantsku,
						:cost_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('item-price')]),
						:size => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('size')]),
						:color1 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('color')]),
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
						:asin => $asin
				}				
				return product, $custError, variant, subvariant				
			else				
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
		parent_sku_arr = $parent_sku.split(/-/)					
		variation_arr = sku_arr - parent_sku_arr
	
		subVariantsp = variation_arr.pop						
		variantsp = variation_arr[0]						
		variantsku = [sku_arr[0],variantsp].join('-')		
		if Variant.find_by_sku(sku).blank?				 
			product = Product.find_or_initialize_by_sku(sku_arr[0])				
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
			variant = Variant.find_or_initialize_by_sku(variantsku)			
			variant.attributes = { :product_id => product.id,
					:sku => variantsku,
					:cost_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('item-price')]),
					:size => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('size')]),
					:color1 => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('color')]),
					:upc => $upc,						
					:sale_price => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('sale-price')]),
					:msrp => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('msrp')]),
					:currency => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('currency')]),
					:leadtime_to_ship => Iconv.conv("UTF-8//IGNORE", "US-ASCII", row[header.index('leadtime-to-ship')]),						
					:asin => $asin
			}			
			return product, $custError , variant
		else
			raise "subvariant"
			createSubVariant row
		end	
  end
end
