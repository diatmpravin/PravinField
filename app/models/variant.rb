class Variant < ActiveRecord::Base
	belongs_to :product
	has_many :variant_updates, :dependent => :destroy
	has_many :variant_images, :dependent => :destroy
	has_many :sub_variants, :dependent => :destroy, :order => 'sub_variants.id ASC'
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable
	
	validates_uniqueness_of :sku
	validates_presence_of :price

  before_validation :nil_if_blank
	after_create :set_default_master
	after_save :generate_skus
	around_destroy :product_master_succession
	#before_update :register_changes

	SEARCH_FIELDS = [ 'sku', 'color1', 'color2','color1_code','color2_code', 'amazon_description' ] 

  def brand
    self.product.brand
  end

	#def register_changes
		
	#end

  def get_last_update
    #TODO return datetime of most recent VariantUpdate or return updated_at for this Variant
  end

	def product_master_succession
		# while deleting, if this was the master previously, then set a new master
		p = self.product
		is_master = self.is_master
		#puts "deleting variant #{self.id}, master? #{is_master}"
		
		yield
		if is_master == true
			p.set_default_master
			#puts "deleted variant. now master is #{p.reload.master.id}"
		end
	end
	
	def set_default_master
		if self.product.master.nil?
			self.is_master = true
		else
			self.is_master = false
		end
		self.save
	end
	
	def set_as_master
		v = self.product.reload.master
		if !v.nil? && self!=v
			v.is_master = false
			v.save
		end
		self.is_master = true
		self.save
	end

	def color_for_amazon
	  "#{self.color1} #{self.color2}".gsub(/[ ]+/,' ').strip
	end

  def name_for_amazon
    #Pearl Izumi Mens Pro LTD Bib Short Prey Black S
    product_name = self.product.name_for_amazon
    return nil if product_name.nil?
    return "#{product_name} #{self.color_for_amazon}"
  end
	
	def currency_for_amazon
	  if self.currency.nil?
	    return 'USD'
	  end
	  return self.currency
	end
	
	# Max length 2000
	def description_for_amazon
	  d = self.amazon_description
    d = self.product.description_for_amazon if d.nil? || d.blank?
    return d[0,2000] if !d.nil?
    return nil
	end
	
	def standard_price_for_amazon
	  [self.price.to_s, 'currency'=>self.currency_for_amazon]
	end
	
	def msrp_for_amazon
    return [self.msrp.to_s, 'currency'=>self.currency_for_amazon] if !self.msrp.nil? && self.msrp>0
	  return self.standard_price_for_amazon
	end
	
	def sale_price_for_amazon
	  return [self.sale_price.to_s, 'currency'=>self.currency_for_amazon] if !self.sale_price.nil? && self.sale_price>0
	  return nil
	end
	
	def get_updated_at
	  arr = self.sub_variants.collect { |sv| sv.updated_at }
	  arr << self.updated_at
	  return arr.max
	end
	
	def get_clean_sku
    SkuPattern.evaluate(self).first

		#p = self.product		
		#b = p.brand.name
		#if b == 'Vogue' 							#VO2648-1437-49
		#	return "#{p.sku}-#{self.color1_code}-#{self.size[0,2]}"
		#elsif b == 'Polo'							#PH3042-900171, PH2053-5003-54
			# if there is only 1 size for the product, then leave it off, otherwise keep it on
		#	return "#{p.sku}-#{self.color1_code}"
		#elsif b == 'Ralph'						#RA4004-10313-59
		#	return "#{p.sku}-#{self.color1_code.gsub(/\//,'')}-#{self.size[0,2]}"
		#elsif b == 'Dolce & Gabbana' 	#DD8039-502-73 vs. 0DD8089-501/8G-5916
			# tricky as there are two versions
			# 0DD1176-814-5217 > DD1176-675-52, DD2192-338 doesn't have size at all, DD3034-154413 same
			# if there is a / in the color1_code, then don't include the size, otherwise do
			# order 4694 has DD2192-338, no slash and yet no size
			#if self.color1_code.include? '/'
		#	return "#{p.sku}-#{self.color1_code.gsub(/\//,'-')}"
			#else
			#	return "#{p.sku}-#{self.color1_code}-#{self.size[0,2]}"
			#end			
		#elsif b == 'Ray-Ban'
		#	return "#{p.sku}-#{self.color1_code}-#{self.size[0,2]}"							#RB3025-13
		#else
		#	return self.sku
		#end
	end

	# searches variants, but returns an ActiveRecord association of the *products* associated with the matched variants
	def self.search(search)
		product_ids_1 = SubVariant.search(search)
		product_ids_2 = select('product_id').where(MwsHelper::search_helper(SEARCH_FIELDS, search)).group('product_id').collect { |v| v.product_id }
	  return (product_ids_1 | product_ids_2)
	end
	
	def get_style
		color1 = self.color1.nil? ? '' : self.color1.strip
		color2 = self.color2.nil? ? '' : self.color2.strip
		return (color1 + ' ' + color2).strip
	end
	
	def get_attributes_for_shopify
		return { 	:price => self.cost_price * (1+self.product.brand.default_markup), 
							:requires_shipping => true,
							:title => "#{self.product.name} (#{get_style})",
							:inventory_quantity => 1,
							:inventory_policy => "deny",
							:taxable => true,
							:grams => self.weight,
							:sku => self.sku,
							:option1 => "#{get_style}",
							:fulfillment_service => "manual" }
	end
	
	def get_image_for_shopify(i)
		if self.variant_images.count >= 1
			desired_width = 320
			if i==0
				desired_width = 400
			end
			vi = self.variant_images.where(:image_width => desired_width).limit(1)
			if !vi.nil? && vi.count>0
				return { :src => vi.first.image.url }
			else
				return { :src => self.variant_images.first.image.url }
			end
		else
			return nil
		end
	end

  def build_mws_messages(listing, feed_type)
    self.sub_variants.collect{ |sv| sv.build_mws_messages(listing,feed_type) }
  end

  # Flatten variables to sku evaluation
  def to_sku_hash
    { 
      'brand'=>self.brand.name,
      'product_sku'=>self.product.sku,
      'product_sku2'=>self.product.sku2,
      'variant_sku'=> self.sku,
      'sku'=>self.sku,
      'color1_code'=>self.color1_code, 
      'color2_code'=>self.color2_code,
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
