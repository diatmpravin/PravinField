require 'amazon/mws'
class SubVariant < ActiveRecord::Base
	belongs_to :variant
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable
	has_many :mws_messages, :as => :matchable # polymorphic association to link an amazon message to either a product or subvariant	
	validates_uniqueness_of :sku
	validates_uniqueness_of :upc, :allow_nil => true

  before_validation :nil_if_blank
	after_save :generate_skus
	
  SEARCH_FIELDS = ['sku', 'size', 'size_code','upc','asin', 'amazon_name']	
	
	def product
	  self.variant.product
	end
	
	def brand		
	  self.variant.product.brand
	end
	
	def variant_images
	  self.variant.variant_images
	end
	
	def self.search(search)
  	select('variant_id').where(MwsHelper::search_helper(SEARCH_FIELDS, search)).group('variant_id').collect { |sv| sv.variant.product_id }.uniq
	end
	
	def upc_for_amazon
	  #TODO deal with fake UPCs for Oakley at least
	  if !self.upc.nil?
	    return { 'Type'=>'UPC', 'Value'=>self.upc[0,12] }
	  elsif !self.asin.nil?
	    return { 'Type'=>'ASIN', 'Value'=>self.asin[0,10] }
	  else
	    return nil
	  end
	end
	
	def name_for_amazon
	  return "#{self.variant.name_for_amazon} #{self.size_code}" 
	end
				
  #TODO make this unique for a store
  def build_mws_messages(listing, feed_type)
    
    if feed_type==MwsRequest::FEED_STEPS[0] #Feed::Enumerations::FEED_TYPES[:product_data]
      m = MwsMessage.create!(:listing_id=>listing.id, :matchable_id=>self.id, :matchable_type=>'SubVariant', :feed_type=>feed_type)
      p = self.product

      description_data = {
        'Title'=>self.name_for_amazon,
        'Brand'=>p.brand.name,
        #'Designer'=>'designer',
        'Description'=>self.variant.description_for_amazon,
        'BulletPoint'=>Product.unpack_keywords(p.bullet_points,5), # max 5
        'ShippingWeight'=>['1','unitOfMeasure'=>'LB']
      }
      description_data.merge!({'MSRP'=>self.variant.msrp_for_amazon}) if !self.variant.msrp_for_amazon.nil?      
      description_data.merge!({
        'SearchTerms'=>Product.unpack_keywords(p.search_keywords,5), # max 5
        'IsGiftWrapAvailable'=>'true',
        'IsGiftMessageAvailable'=>'true'
        #'RecommendedBrowseNode'=>'60583031', # only for Europe
      })

      variation_data = { 'Parentage'=>'child' }
      variation_data.merge!({ 'Size'=>self.size }) if !self.size.nil?
      variation_data.merge!({ 'Color'=>self.variant.color_for_amazon, 'VariationTheme'=>p.variation_theme })
      
      product_data = {
        'Clothing'=>{
          'VariationData'=> variation_data,
          'ClassificationData'=>{
            'ClothingType'=>p.product_type,
            'Department'=>Product.unpack_keywords(p.department, 10), # max 10
            'StyleKeywords'=>Product.unpack_keywords(p.style_keywords,10),  # max 10
            'OccasionAndLifestyle'=>Product.unpack_keywords(p.occasion_lifestyle_keywords,10) # max 10
          }#ClassificationData
        }#Clothing
      }#ProductData        
      
      product = { 'SKU'=>self.sku }
      product.merge!({'StandardProductID'=>self.upc_for_amazon}) if !self.upc_for_amazon.nil?
      product.merge!({
        'ProductTaxCode'=>'A_GEN_NOTAX',                 
        'ItemPackageQuantity'=>'1',
        'NumberOfItems'=>'1',
        'DescriptionData'=>description_data,
        'ProductData'=>product_data
      })
      
      row = {
        'MessageID'=>m.id,
        'OperationType'=>listing.operation_type,
        'Product'=>product
      }
      m.update_attributes!(:message => row)
      return row
    elsif feed_type==MwsRequest::FEED_STEPS[1] #Feed::Enumerations::FEED_TYPES[:product_relationship_data]
      # This one is not a separate message, but just a repeated element within the relationship message
      return [{ 'SKU'=>self.sku, 'Type'=>'Variation' }]
    elsif feed_type==MwsRequest::FEED_STEPS[2] #Feed::Enumerations::FEED_TYPES[:product_pricing]
      m = MwsMessage.create!(:listing_id=>listing.id, :matchable_id=>self.id, :matchable_type=>'SubVariant', :feed_type=>feed_type)
      
      price = {'SKU'=>self.sku, 'StandardPrice'=>self.variant.standard_price_for_amazon}
      
      if !self.variant.sale_price_for_amazon.nil?
        price.merge!(
          {'Sale'=>{
            'StartDate' => '2004-03-03T00:00:00Z', #TODO
            'EndDate' => '2020-03-03T00:00:00Z', #TODO
            'SalePrice' => self.variant.sale_price_for_amazon
            }
          })
      end
      
      row = {
        'MessageID' => m.id,
        'OperationType' => listing.operation_type,
        'Price' => price
      }
      m.update_attributes(:message => row)
      return row
    elsif feed_type==MwsRequest::FEED_STEPS[3] #Feed::Enumerations::FEED_TYPES[:product_image_data]
      rows = []
      self.variant_images.each_with_index do |vi,i|
        m = MwsMessage.create!(:listing_id=>listing.id, :matchable_id=>self.id, :matchable_type=>'SubVariant', :variant_image_id=>vi.id, :feed_type=>feed_type)
        row = {
            'MessageID' => m.id,
            'OperationType' => listing.operation_type,
            'ProductImage' => {
              'SKU' => self.sku,
              'ImageType' => i==0 ? 'Main' : "PT#{i}",
              'ImageLocation' => vi.image.url
            }
        }
        m.update_attributes(:message => row)
        rows << row
      end
      return rows
    elsif feed_type==MwsRequest::FEED_STEPS[4] #Feed::Enumerations::FEED_TYPES[:inventory_availability]
      m = MwsMessage.create!(:listing_id=>listing.id, :matchable_id=>self.id, :matchable_type=>'SubVariant', :feed_type=>feed_type)
      row = {
        'MessageID' => m.id,
        'OperationType' => listing.operation_type,
        'Inventory' => {
          'SKU' => self.sku,
          #'FulfillmentCenterID' => 'Boston', #Option seller defined fulfillment center
          'Quantity' => self.quantity ||=0,
          'FulfillmentLatency' => self.fulfillment_latency.nil? ? self.brand.fulfillment_latency : self.fulfillment_latency
          #'SwitchFulfillmentTo' => 'AFN' # Used only when switching fulfillment from AFN to MFN or back
        }#Inventory
      }
      m.update_attributes(:message => row)
      return row
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
	
  def nil_if_blank
    SEARCH_FIELDS.each { |attr| self[attr] = nil if self[attr].blank? }
  end
  	  
  def generate_skus
    SkuMapping.auto_generate(self)
  end
	
end
