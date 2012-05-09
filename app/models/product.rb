require 'amazon/mws'
class Product < ActiveRecord::Base
	acts_as_taggable
	belongs_to :brand
	has_many :listings, :dependent => :destroy
  has_many :queued_listings, :class_name => 'Listing', :conditions => ["listings.status=?", 'queued'], :order => 'listings.id ASC'	
	has_many :active_listings, :class_name => 'Listing', :conditions => ["listings.status=?", 'active'], :order => 'listings.built_at ASC'
  has_many :error_listings, :class_name => 'Listing', :conditions => ["listings.status=?", 'error'], :order => 'listings.built_at ASC'
	has_many :stores, :through => :active_listings # Stores relation only works for active listings, ignores all others
	has_many :mws_messages, :as => :matchable # polymorphic association to link an amazon message to either a product or subvariant
	has_many :sub_variants, :through => :variants
	has_many :variant_images, :through => :variants
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable

	has_many :variants, :dependent => :destroy, :order => "variants.id ASC"

  has_one :master, :class_name => 'Variant',
      		:conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", true]	
	
  has_many :variants_excluding_master,
      :class_name => 'Variant',
      :conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", false],
      :order => "variants.position ASC"
	
	validates_presence_of :brand_id
	validates_associated :brand
	validates_uniqueness_of :sku, :scope => [:brand_id]
	
	validates_presence_of :name, :if => 'amazon_name.nil?'
  
  before_validation :nil_if_blank
	after_save :generate_skus

  SEARCH_FIELDS = [ 'name', 'description', 'amazon_name', 'amazon_description', 'meta_description', 'meta_keywords', 'sku', 'category' ]

  def self.require_subvariant
    Product.all.each do |p|
      p.variants.each do |v|
        if v.subvariants.nil?
          # create a single master subvariant
          SubVariant.create!(:variant_id=>v.id, :sku=>v.sku, :upc=>v.upc, :asin=>v.asin, :size=>v.size, :availability=>v.availability, :size_code=>v.size_code)
        end
      end
    end
  end

  # Search several text fields of the product for a search string and return products query
	def self.search(search)
		# get sub_matches from variants
		o1 = Variant.search(search)
		
		# get direct matches at order level
		# TODO searching a brand won't work here
		bind_vars = MwsHelper::search_helper(SEARCH_FIELDS, search)
		o2 = select('id').where(bind_vars).collect { |p| p.id }
			
		# combine the two arrays of IDs and remove duplicates, and return all relevant records
		where(:id => o1 | o2)
	end

	# If product does not have a master variant, then set the first variant as master
	def set_default_master	
		variants = self.reload.variants
		master = self.reload.master
		if variants.count >= 1 && master.nil?
			variants[0].is_master = true
			variants[0].save
		end
	end

  #TODO replace this with a more elegant method
	def self.refresh_all_sku_mappings
		Product.all.each do |p|
			p.variants.each do |v|
				v.sub_variants.each do |sv|
					sv.save
				end
				v.save
			end
			p.save
		end
	end

  #def get_last_update
    #TODO return datetime of most recent value for get_last_update for each variant of this product
  #end

  # return a hash structured to list this product on Shopify
  #TODO rename to as_shopify
  def attributes_for_shopify
	  variants_arr = Array.new
	  images_arr = Array.new 
	  i = 0
	  self.variants.each do |v|
		  variants_arr << v.attributes_for_shopify
		  images_arr << v.image_for_shopify(i)
		  i += 1
	  end
	
	  to_publish = true
	  if images_arr.count==0
		  to_publish = false
	  end

	  brand = self.brand		
	  return {
	      :product_type => self.category,
			  :title => self.name,
			  :body_html => self.description,
			  :images => images_arr,
			  :variants => variants_arr,
			  :published => to_publish,
			  :tags => "#{brand} #{self.category}, #{brand.name} #{self.name}",
			  :vendor => brand.name,
			  :options => [ {:name => 'Color'}]
		} 
  end

  def self.unpack_keywords(keywords, max)
    if keywords.nil? || keywords.blank?
      return nil
    end
    keywords.split(Import::KEYWORD_DELIMITER, max)
  end

  def name_for_amazon
    return "#{self.brand.name} #{self.department} #{self.name}" if self.amazon_name.nil? || self.amazon_name.blank?
    return self.amazon_name
  end
  
  def description_for_amazon
	  d = self.amazon_description
    d = self.description if d.nil? || d.blank?
    return d[0,2000] if !d.nil?
    return nil
  end
  
  #TODO make this specific to a store
  def build_mws_messages(listing, feed_type)
    
    if feed_type==MwsRequest::FEED_STEPS[0] #'product_data'
      m = MwsMessage.create!(:listing_id=>listing.id, :matchable_id=>self.id, :matchable_type=>'Product', :feed_type=>feed_type)
      rows = self.variants.collect { |v| v.build_mws_messages(listing, feed_type) }.flatten

      rows.unshift({
        'MessageID'=>m.id,
        'OperationType'=>listing.operation_type,
        'Product'=> {
          'SKU'=>self.sku,
          'ProductTaxCode'=>'A_GEN_NOTAX',
          'ItemPackageQuantity'=>'1',
          'NumberOfItems'=>'1',
          'DescriptionData'=>{
            'Title'=>self.name_for_amazon,
            'Brand'=>self.brand.name,
            #'Designer'=>'designer',
            'Description'=>self.description_for_amazon,
            'BulletPoint'=>Product.unpack_keywords(self.bullet_points,5), # max 5
            'ShippingWeight'=>['1', 'unitOfMeasure'=>'LB'],
            'SearchTerms'=>Product.unpack_keywords(self.search_keywords,5), # max 5
            'IsGiftWrapAvailable'=>'true',
            'IsGiftMessageAvailable'=>'true'
            #'RecommendedBrowseNode'=>'60583031', # only for Europe
          },#DescriptionData
          'ProductData' => {
            'Clothing'=>{
              "VariationData"=> {
                "Parentage"=>"parent",
                "VariationTheme"=>self.variation_theme,
              },#VariationData
              'ClassificationData'=>{
                'ClothingType'=>self.product_type,
                'Department'=>Product.unpack_keywords(self.department, 10), # max 10
                'StyleKeywords'=>Product.unpack_keywords(self.style_keywords,10),  # max 10
                'OccasionAndLifestyle'=>Product.unpack_keywords(self.occasion_lifestyle_keywords,10) # max 10
              }
            }#Clothing
          }#ProductData
        }#Product
      })
      m.update_attributes!(:message => rows[0])
      return rows
    
    elsif listing.operation_type == 'Delete'
      return [] # if this is a delete listing, it is not necessary to submit anything further

    elsif feed_type==MwsRequest::FEED_STEPS[1] # 'product_relationship_data'
      m = MwsMessage.create!(:listing_id=>listing.id, :matchable_id=>self.id, :matchable_type=>'Product', :feed_type=>feed_type)
      rows = self.variants.collect { |v| v.build_mws_messages(listing, feed_type) }.flatten
      
      relation_rows = rows.collect { |r| {'Relation' => r} }
      
      row = [{
        'MessageID'=>m.id,
        'OperationType'=>listing.operation_type,        
        'Relationship'=>['ParentSKU'=>self.sku]+relation_rows
      }]
      m.update_attributes!(:message => row[0])
      return row
      
    else
      rows = self.variants.collect { |v| v.build_mws_messages(listing, feed_type) }.flatten      
      return rows
    end
      
  end

  # Flatten variables for sku evaluation
  def to_sku_hash
    { 
      'brand'=>self.brand.name, 
      'product_sku'=>self.sku,
      'sku'=>self.sku,
      'sku2'=>self.sku2
    }    
  end

  def get_updated_at
	  arr = self.variants.collect { |v| v.get_updated_at }
	  arr << self.updated_at
	  return arr.max    
  end
  
  protected

  def nil_if_blank
    SEARCH_FIELDS.each { |attr| self[attr] = nil if self[attr].blank? }
  end  
  
  def generate_skus
    SkuMapping.auto_generate(self)
  end	

end
