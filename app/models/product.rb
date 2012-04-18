class Product < ActiveRecord::Base
	belongs_to :brand
	has_many :listings, :dependent => :destroy
	has_many :stores, :through => :listings
	has_many :variants, :dependent => :destroy
	has_many :mws_order_items#, :foreign_key => 'parent_product_id'
	validates_associated :brand
	
	after_save :save_sku_mappings

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
	
	validates :name, :presence => true
	validates_presence_of :brand_id
	validates_uniqueness_of :base_sku, :scope => [:brand_id]

	def self.search(search)
		# get sub_matches from order_items
		o1 = Variant.search(search).collect { |v| v.product_id }
		
		# get direct matches at order level
		# TODO searching a brand won't work here
		fields = [ 'name', 'description', 'meta_description', 'meta_keywords', 'base_sku', 'category' ]
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

  # return a hash structured to list this product on Shopify
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

	#sku	product-id	product-id-type	product-name	brand	bullet-point1	bullet-point2	bullet-point3	bullet-point4	bullet-point5	product-description	clothing-type	size	size-modifier	color	color-map	material-fabric1	material-fabric2	material-fabric3	department1	department2	department3	department4	department5	style-keyword1	style-keyword2	style-keyword3	style-keyword4	style-keyword5	occasion-lifestyle1	occasion-lifestyle2	occasion-lifestyle3	occasion-lifestyle4	occasion-lifestyle5	search-terms1	search-terms2	search-terms3	search-terms4	search-terms5	size-map	waist-size-unit-of-measure	waist-size	inseam-length-unit-of-measure	inseam-length	sleeve-length-unit-of-measure	sleeve-length	neck-size-unit-of-measure	neck-size	chest-size-unit-of-measure	chest-size	cup-size	shoe-width	parent-child	parent-sku	relationship-type	variation-theme	main-image-url	swatch-image-url	other-image-url1	other-image-url2	other-image-url3	other-image-url4	other-image-url5	other-image-url6	other-image-url7	other-image-url8	shipping-weight-unit-measure	shipping-weight	product-tax-code	launch-date	release-date	msrp	item-price	sale-price	currency	fulfillment-center-id	sale-from-date	sale-through-date	quantity	leadtime-to-ship	restock-date	max-aggregate-ship-quantity	is-gift-message-available	is-gift-wrap-available	is-discontinued-by-manufacturer	registered-parameter	update-delete	
  def attributes_for_amazon(feed_type)
    if feed_type==:product_data
      #TODO must be completed for product data and other feed types
      return {
		    'sku' => self.base_sku,
		    'brand' => self.brand.name,
		    'product-name' => self.name
		  }
    end
  end

	protected
	def save_sku_mappings
		#SkuMapping.where(:granularity=>'product',:foreign_id=>self.id,:source=>'auto').each do |sm|
		#	sm.destroy
		#end
	end
	
end
