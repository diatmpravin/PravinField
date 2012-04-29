class Product < ActiveRecord::Base
	belongs_to :brand
	has_many :listings, :dependent => :destroy
	has_many :stores, :through => :listings
	has_many :variants, :dependent => :destroy
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable

  has_one :master, :class_name => 'Variant',
      		:conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", true]	
	
  has_many :variants_excluding_master,
      :class_name => 'Variant',
      :conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", false],
      :dependent => :destroy, #added this
      :order => "variants.position ASC"

  has_many :variants,
      :class_name => 'Variant',
      :conditions => ["variants.deleted_at IS NULL"],
      :dependent => :destroy,
      :order => "variants.position ASC, variants.id ASC"

  has_many :variants_with_only_master,
      :class_name => 'Variant',
      :conditions => ["variants.deleted_at IS NULL AND variants.is_master = ?", true],
      :dependent => :destroy
	
	validates_presence_of :brand_id, :name
	validates_associated :brand
	validates_uniqueness_of :sku, :scope => [:brand_id]
  
	after_save :generate_skus

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
		fields = [ 'name', 'description', 'meta_description', 'meta_keywords', 'sku', 'category' ]
		bind_vars = MwsHelper::search_helper(fields, search)
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

  def get_last_update
    #TODO return datetime of most recent value for get_last_update for each variant of this product
  end

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
  
  #TODO make this specific to a store
  def attributes_for_amazon(feed_type)
    rows = []
    self.variants.each do |v| 
      rows += v.attributes_for_amazon(feed_type)
    end
    
    if feed_type==:product_data
      return rows.unshift({
        'Product'=> {
          'SKU'=>self.sku,
          'ItemPackageQuantity'=>'1',
          'NumberOfItems'=>'1',
          #'StandardProductID'=>{'Type'=>'UPC', 'Value'=>'814digitstring'},
          'DescriptionData'=>{
            'Title'=>self.name,
            'Brand'=>self.brand.name,
            #'Designer'=>'designer',
            'Description'=>self.description.nil? ? nil : self.description[0,2000], # max length 2000
            'BulletPoint'=>Product.unpack_keywords(self.bullet_points,5), # max 5
            'ShippingWeight'=>{'unitOfMeasure'=>'LB', 'Value'=>'1'}, #TODO value is probably not the right term
            #'MSRP'=>'5.43',
            'SearchTerms'=>Product.unpack_keywords(self.search_keywords,5), # max 5
            #'IsGiftWrapAvailable'=>'True',
            #'IsGiftMessageAvailable'=>'True'
            #'RecommendedBrowseNode'=>'60583031', # only for Europe
          },#DescriptionData
          'ProductData' => {
            'Clothing'=>{
              "VariationData"=> {
                "Parentage"=>"parent", 
                #"Size"=>"size", 
                #"Color"=>"color", 
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

    elsif feed_type==:product_relationship_data
      return [{
        'Relationship'=>{
          'ParentSKU'=>self.sku,
          'Relation'=>rows
        }#Relationship
      }]
      
    elsif feed_type==:product_image_data
      return rows
    elsif feed_type==:product_pricing
      return rows
    elsif feed_type==:inventory_availability
      
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

  protected
  def generate_skus
    SkuMapping.auto_generate(self)
  end	

end
