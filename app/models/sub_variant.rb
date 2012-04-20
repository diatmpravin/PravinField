class SubVariant < ActiveRecord::Base
	belongs_to :variant
	
	has_many :mws_order_items#, :foreign_key => 'parent_sub_variant_id'
	
	###
	has_many :sku_mappings, :as=>:sku_mapable
	###
	
	validates_uniqueness_of :sku
	validates_uniqueness_of :upc, :allow_nil => true
	after_save :save_sku_mappings
	
	def product
	  self.variant.product
	end
	
	def brand
	  self.variant.product.brand
	end
	
	protected	
	def save_sku_mappings	
	  SkuMapping.auto_generate(self)
  end
	
end
