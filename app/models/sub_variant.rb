class SubVariant < ActiveRecord::Base
	belongs_to :variant
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable
	
	validates_uniqueness_of :sku
	validates_uniqueness_of :upc, :allow_nil => true

	after_save :generate_skus
	
	def product
	  self.variant.product
	end
	
	def brand		
	  self.variant.product.brand
	end
	
	def self.search(search)
    fields = ['sku', 'size', 'size_code','UPC','ASIN']
  	select('variant_id').where(MwsHelper::search_helper(fields, search)).group('variant_id').collect { |sv| sv.variant.product_id }.uniq
	end
	
	def upc_for_amazon
	  #TODO deal with fake UPCs for Oakley at least
	  if !self.upc.nil?
	    return {'Type'=>'UPC', 'Value'=>self.upc}
	  elsif !self.asin.nil?
	    return {'Type'=>'ASIN', 'Value'=>self.asin}
	  else
	    return nil
	  end
	end

  #TODO make this unique for a store
  def attributes_for_amazon(feed_type)
    if feed_type==:product_data
      p = self.product
      return [{
        'Product'=> {
          'SKU'=>self.sku,
          'ItemPackageQuantity'=>'1',
          'NumberOfItems'=>'1',
          'StandardProductID'=>self.upc_for_amazon,
          'DescriptionData'=>{
            'Title'=>p.name,
            'Brand'=>p.brand.name,
            #'Designer'=>'designer',
            'Description'=>p.description.nil? ? nil : p.description[0,2000], # max length 2000
            'BulletPoint'=>Product.unpack_keywords(p.bullet_points,5), # max 5
            'ShippingWeight'=>{'unitOfMeasure'=>'LB', 'Value'=>'1'}, #TODO value is probably not the right term
            'MSRP'=>self.variant.msrp.to_s,
            'SearchTerms'=>Product.unpack_keywords(p.search_keywords,5), # max 5
            #'IsGiftWrapAvailable'=>'True',
            #'IsGiftMessageAvailable'=>'True'
            #'RecommendedBrowseNode'=>'60583031', # only for Europe
          },#DescriptionData
          'ProductData' => {
            'Clothing'=>{
              'VariationData'=> {
                'Parentage'=>'child', 
                'Size'=>self.size,
                'Color'=>self.variant.color1,
                'VariationTheme'=>p.variation_theme,
              },#VariationData
              'ClassificationData'=>{
                'ClothingType'=>p.product_type,
                'Department'=>Product.unpack_keywords(p.department, 10), # max 10
                'StyleKeywords'=>Product.unpack_keywords(p.style_keywords,10),  # max 10
                'OccasionAndLifestyle'=>Product.unpack_keywords(p.occasion_lifestyle_keywords,10) # max 10
              }#ClassificationData
            }#Clothing
          }#ProductData
        }#Product
      }] 
    elsif feed_type==:product_relationship_data
      return [{ 'SKU'=>self.sku, 'Type'=>'Variation' }]
    elsif feed_type==:product_image_data
      rows = []
      self.variant.variant_images.each_with_index do |vi,i|
        rows << {'ProductImage' => {
            'SKU' => self.sku,
            'ImageType' => i==0 ? 'Main' : "PT#{i}",
            'ImageLocation' => vi.image.url
          }}
      end
      return rows
    elsif feed_type==:product_pricing
      return [{ 
        'Price' => {
          'SKU'=>self.sku,
          'StandardPrice' => self.variant.price.to_s, #TODO currency, should be of type OverrideCurrencyAmount
          'Sale' => {
            'StartDate' => '2004-03-03T00:00:00Z',
            'EndDate' => '2020-03-03T00:00:00Z',
            'SalePrice' => self.variant.sale_price.to_s #TODO format
          }#Sale
        }#Price
      }]
    elsif feed_type==:inventory_availability
      return [{
        'Inventory' => {
          'SKU' => self.sku,
          #'FulfillmentCenterID' => 'Boston', #Option seller defined fulfillment center
          'Quantity' => self.quantity,
          'FulfillmentLatency' => self.fulfillment_latency.nil? ? self.brand.fulfillment_latency : self.fulfillment_latency
          #'SwitchFulfillmentTo' => 'AFN' # Used only when switching fulfillment from AFN to MFN or back
        }#Inventory
      }]
    end    
  end
	
  # Flatten variables and send to SkuMapping for evaluation
  def to_sku_hash
    { 
      'brand'=>self.brand.name,
      'variant_sku'=> self.variant.sku,
      'product_sku'=>self.product.sku,
      'product_sku2'=>self.product.sku2,
      'sub_variant_sku'=>self.sku,
      'sku'=>self.sku,
      'color1_code'=>self.variant.color1_code,
      'color2_code'=>self.variant.color2_code, 
      'size'=>self.size,
      'size_code'=>self.size_code
    }    
  end
  
	protected  
  def generate_skus
    SkuMapping.auto_generate(self)
  end
	
end
