class SkuMapping < ActiveRecord::Base
  belongs_to :sku_mapable, :polymorphic => true
  
	validates_uniqueness_of :sku
	validates_inclusion_of :sku_mapable_type, :in=>%w(Product Variant SubVariant), :message => 'Invalid sku mapable type'
	validates_inclusion_of :source, :in=>%w(manual auto), :message=>'Invalid source'
	validates_numericality_of :sku_mapable_id, { :only_integer => true, :greater_than => 0 }

	# accepts a sku string and returns the product, variant, or sub_variant that it matches, or nil if no match
	def self.get_catalog_match(sku)
		sm = SkuMapping.find_by_sku(SkuPattern.strip_amazon_suffix(sku).upcase)
		if !sm.nil?
		  return sm.sku_mapable
		end
		return nil
	end

  # delete old auto generated mappings and create new auto mappings for a given product / variant / sub_variant
	def self.auto_generate(o)	  
    o.sku_mappings.where(:source=>'auto').destroy_all
    SkuPattern.evaluate(o).each do |sku|
	    SkuMapping.create(:sku=>sku, :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')  
    end
  end
      
end
