class Variant < ActiveRecord::Base
	belongs_to :product
	has_many :variant_updates, :dependent => :destroy
	has_many :variant_images, :dependent => :destroy
	has_many :sub_variants, :dependent => :destroy
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable
	
	validates_uniqueness_of :sku

	after_create :set_default_master
	after_save :generate_skus
	around_destroy :product_master_succession
	#before_update :register_changes

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

	def get_clean_sku
		p = self.product		
		b = p.brand.name
		if b == 'Vogue' 							#VO2648-1437-49
			return "#{p.base_sku}-#{self.color1_code}-#{self.size[0,2]}"
		elsif b == 'Polo'							#PH3042-900171, PH2053-5003-54
			# if there is only 1 size for the product, then leave it off, otherwise keep it on
			return "#{p.base_sku}-#{self.color1_code}"
		elsif b == 'Ralph'						#RA4004-10313-59
			return "#{p.base_sku}-#{self.color1_code.gsub(/\//,'')}-#{self.size[0,2]}"
		elsif b == 'Dolce & Gabbana' 	#DD8039-502-73 vs. 0DD8089-501/8G-5916
			# tricky as there are two versions
			# 0DD1176-814-5217 > DD1176-675-52, DD2192-338 doesn't have size at all, DD3034-154413 same
			# if there is a / in the color1_code, then don't include the size, otherwise do
			# order 4694 has DD2192-338, no slash and yet no size
			#if self.color1_code.include? '/'
			return "#{p.base_sku}-#{self.color1_code.gsub(/\//,'-')}"
			#else
			#	return "#{p.base_sku}-#{self.color1_code}-#{self.size[0,2]}"
			#end			
		elsif b == 'Ray-Ban'
			return "#{p.base_sku}-#{self.color1_code}-#{self.size[0,2]}"							#RB3025-13
		else
			return self.sku
		end
	end

	# searches variants BUT returns an ActiveRecord association of the products associated with the matched variants
	def self.search(search)
		fields = [ 'sku', 'upc', 'size', 'color1', 'color2','color1_code','color2_code','availability', 'amazon_product_name', 'amazon_product_id', 'amazon_product_description' ] 
		select('product_id').where(MwsHelper::search_helper(fields, search)).group('product_id')
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

	protected
  # Flatten variables and send to SkuMapping for evaluation
  def generate_skus
    SkuMapping.auto_generate(self, { 
      'brand'=>self.brand.name, 
      'sku'=>self.sku, 
      'base_sku'=>self.product.base_sku, 
      'color1_code'=>self.color1_code, 
      'size'=>self.size 
    })
  end	
		
end
