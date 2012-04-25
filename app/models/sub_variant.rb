class SubVariant < ActiveRecord::Base
	belongs_to :variant
	has_many :mws_order_items
	has_many :sku_mappings, :as=>:sku_mapable
	
	validates_uniqueness_of :sku
	validates_uniqueness_of :upc, :allow_nil => true

	#after_save :generate_skus
	
	def product
	  self.variant.product
	end
	
	def brand		
	  self.variant.product.brand
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
