
class Import < ActiveRecord::Base
  has_attached_file :input_file
  has_attached_file :error_file

  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  attr_accessible :error_file, :format, :import_date, :input_file, :status
  validates_presence_of :import_date
  
	def self.build_from_csv(parentRows,row)		
    prev_brand_name = nil
    prev_brand = nil    
    #raise header.index('brand').inspect
    brand_name = row[header.index('brand')] # lookup brandId then row brand    
    #if brand_name == prev_brand_name
    #	brand = prev_brand 
    #else
    #	prev_brand_name = brand_name
    #end 
    
    unless Brand.find_by_name(brand_name).nil?    
	 		$brandId = Brand.find_by_name(brand_name).id			 		  
		  unless SkuPattern.find_by_brand_id($brandId).blank?   
				if row[header.index('parent-child')] == 'parent'
					sku = row[header.index('sku')]					
					#raise Product.find_or_initialize_by_sku(sku).blank?.inspect				
					if Product.where(:sku => sku).blank?
						product = Product.new						
						product.attributes = { :name => row[header.index('product-name')],
							:description => row[header.index('product-description')],    			
							#:deleted_at => row[header.index('deleted_at')],
							:available_on => row[header.index('release-date')],
							#:meta_description => row[header.index('meta_description')],
							#:meta_keywords => row[header.index('meta_keywords')],
							:brand_id => $brandId,
							:sku => row[header.index('sku')],
							#:category => row[header.index('category')],
							:product_type => row[header.index('clothing-type')],
							:variation_theme => row[header.index('variation-theme')],
							:department => row[header.index('department1')],
							:file_date => row[header.index('date')],
							:amazon_template => 'Clothing',
							:keywords => row[header.index('style-keyword1')],
							:keywords2 => [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t"),
							:keywords3 => [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t")
						}						
						return product			
					else
							
					end
					
				else				
					sku = row[header.index('sku')].gsub(/-AZ.*$/,'')
					sku_arr = sku.split(/-/)										
					parent_sku = row[header.index('parent-sku')]					
					parent_sku_arr = parent_sku.split(/-/)					
					variation_arr = sku_arr - parent_sku_arr
					
					variation_theme = row[header.index('variation-theme')]
					
					upc = nil
					asin = nil
					
					if row[header.index('product-id-type')] == 'UPC'
						upc = row[header.index('product-id')]
					elsif row[header.index('product-id-type')] == 'ASIN'
						asin = row[header.index('product-id')]
					end
					
					if variation_arr.size == 2						
						subVarientsp = variation_arr.pop						
						varientsp = variation_arr[0]						
						varientsku = [sku_arr[0],varientsp].join('-')						
						if Variant.find_by_sku(varientsku).blank?
							if Product.find_by_sku(sku_arr[0]).nil?
								product = Product.new	  						
								product.attributes = { :name => row[header.index('product-name')],
									:description => row[header.index('product-description')],    			
									#:deleted_at => row[header.index('deleted_at')],
									:available_on => row[header.index('release-date')],
									#:meta_description => row[header.index('meta_description')],
									#:meta_keywords => row[header.index('meta_keywords')],
									:brand_id => $brandId,
									:sku => row[header.index('sku')],
									#:category => row[header.index('category')],
									:product_type => row[header.index('clothing-type')],
									:variation_theme => row[header.index('variation-theme')],
									:department => row[header.index('department1')],
									:file_date => row[header.index('date')],
									:amazon_template => 'Clothing',
									:keywords => row[header.index('style-keyword1')],
									:keywords2 => [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t"),
									:keywords3 => [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t")
								}						
								#raise product.inspect								
							end
							#raise "about to crate variant"
							variant = Variant.new
							#raise variant.inspect
							#raise row[header.index('product-id')].inspect
							variant.attributes = { :product_id => row[header.index('product-id')],
									:sku => varientsku,
									:cost_price => row[header.index('item-price')],
									:currency => row[header.index('currency')],
									:msrp => row[header.index('msrp')],
									:sale_price => row[header.index('sale-price')],
									:leadtime_to_ship => row[header.index('leadtime-to-ship')],
									:upc => upc,
									:asin => asin
							}
							#raise variant.inspect
							subvarient = SubVariant.new
							#raise row[header.index('sku')].inspect							
							subvarient.attributes = { #:variant_id => row[header.index('variant-id')],
									:sku => row[header.index('sku')],
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
								product.attributes = { :name => row[header.index('product-name')],
									:description => row[header.index('product-description')],    			
									#:deleted_at => row[header.index('deleted_at')],
									:available_on => row[header.index('release-date')],
									#:meta_description => row[header.index('meta_description')],
									#:meta_keywords => row[header.index('meta_keywords')],
									:brand_id => $brandId,
									:sku => parent_sku,
									#:category => row[header.index('category')],
									:product_type => row[header.index('clothing-type')],
									:variation_theme => row[header.index('variation-theme')],
									:department => row[header.index('department1')],
									:file_date => row[header.index('date')],
									:amazon_template => 'Clothing',
									:keywords => row[header.index('style-keyword1')],
									:keywords2 => [row[header.index('occasion-lifestyle1')],row[header.index('occasion-lifestyle2')],row[header.index('occasion-lifestyle3')],row[header.index('occasion-lifestyle4')],row[header.index('occasion-lifestyle5')]].join("\t"),
									:keywords3 => [row[header.index('search-terms1')],row[header.index('search-terms2')],row[header.index('search-terms3')],row[header.index('search-terms4')],row[header.index('search-terms5')]].join("\t")
								}						
								#raise product.inspect								
							end
							#raise "about to crate variant"
							#raise "about to crate variant"
							variant = Variant.new
							#raise variant.inspect
							#raise row[header.index('product-id')].inspect
							variant.attributes = { :product_id => row[header.index('product-id')],
									:sku => sku,
									:cost_price => row[header.index('item-price')],
									:currency => row[header.index('currency')],
									:msrp => row[header.index('msrp')],
									:sale_price => row[header.index('sale-price')],
									:leadtime_to_ship => row[header.index('leadtime-to-ship')],
									:upc => upc,
									:asin => asin
							}
							raise variant.inspect
						else
							raise "variant present"
						end
						raise "Maisa"
					end
					
					if !parent_sku.nil? && !variation_theme.nil?
						#raise "not nil"
						#begin														
							if Product.where(:sku => sku).blank?
								varientProduct = Product.new
								if variation_theme == 'SizeColor' || variation_theme == 'color'
									#raise row[header.index('color')].inspect
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
				end
			else
				raise "false"	
			end	
    else
    	raise "false"
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
  end
  
end
