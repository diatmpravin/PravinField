class SubVariant < ActiveRecord::Base
	belongs_to :variant
	has_many :mws_order_items#, :foreign_key => 'parent_sub_variant_id'
	
	validates_uniqueness_of :sku
	validates_uniqueness_of :upc, :allow_nil => true
	after_save :save_sku_mappings
	
	def save_sku_mappings
	  SkuMapping.clear_auto('sub_variant', self.id)
		last_two = self.sku[self.sku.length-2,2]
		if last_two == '.0'
			SkuMapping.create(:sku=>self.sku[0,self.sku.length-3],:granularity=>'sub_variant',:foreign_id=>self.id,:source=>'auto')
		end
	end	
	
end
