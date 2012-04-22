class Import < ActiveRecord::Base
  has_attached_file :input_file
  has_attached_file :error_file

  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  attr_accessible :error_file, :format, :import_date, :input_file, :status
  validates_presence_of :import_date
  
	def self.build_from_csv(parentRows,row)
		##USER TABLE
		#raise row[1].inspect
		#data = row[0].split(',')
    #raise data.inspect
    #cust = User.find_or_initialize_by_email(data[1])    
    #cust.attributes ={:name => data[0],
    #  :email => data[1],
    #  :password => data[2]}
    #return cust
    
    ## PRODUCT TABLE
    #raise header.inspect
    #raise row.inspect
    prev_brand_name = nil
    prev_brand = nil
    brand_name = row[header.index('brand')] # lookup brandId then row brand
    #if brand_name == prev_brand_name
    #	brand = prev_brand 
    #else
    #	prev_brand_name = brand_name
    #end 
    unless Brand.find_by_name(brand_name).nil?    
	 		brandId = Brand.find_by_name(brand_name).id		  
		  unless SkuPattern.find_by_brand_id(brandId).blank?   
				if row[header.index('parent-child')] == 'parent'
					sku = row[header.index('sku')]
					#raise sku.inspect
					#raise Product.find_or_initialize_by_sku(sku).blank?.inspect
					#raise header.index('release-date').inspect
					#raise row[header.index('release-date')].inspect
					if Product.where(:sku => sku).blank?
						product = Product.new
						product.attributes = { :name => row[header.index('product-name')],
							:description => row[header.index('product-description')],    			
							#:deleted_at => row[header.index('deleted_at')],
							:available_on => row[header.index('release-date')],
							#:meta_description => row[header.index('meta_description')],
							#:meta_keywords => row[header.index('meta_keywords')],
							#:brand_id => row[header.index('brand_id')],
							:sku => row[header.index('sku')],
							#:category => row[header.index('category')],
							#:product_type => row[header.index('product_type')],
							#:variation_theme => row[header.index('variation_theme')],
							#:file_data => row[header.index('file_data')],
							#:amazon_template => row[header.index('amazon_template')],
							#:keywords => row[header.index('keywords')],
							#:keywords2 => row[header.index('keywords2')],
							#:keywords3 => row[header.index('keywords3')]
						}
						return product			
					else
							
					end
					#raise Product.find_or_initialize_by_sku('0265663').inspect
				else
					#raise parentRows.inspect
					#raise row.inspect
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
  	#raise row.inspect
  	$header = row
  	#raise row.inspect
  	header
  	return header
  end
  
  def self.header
  	#raise $header.inspect
  	return $header
  end
  
end
