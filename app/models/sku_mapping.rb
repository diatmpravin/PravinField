class SkuMapping < ActiveRecord::Base
	validates_uniqueness_of :sku
	validates_inclusion_of :sku_mapable_type, :in=>%w(Product Variant SubVariant), :message => 'Invalid sku mapable type'
	validates_inclusion_of :source, :in=>%w(manual auto), :message=>'Invalid source'
	validates_numericality_of :sku_mapable_id, { :only_integer => true, :greater_than => 0 }

  ###
  belongs_to :sku_mapable, :polymorphic => true
  ###
		
	def self.get_catalog_match(sku)
		sm = SkuMapping.find_by_sku(sku)
		if !sm.nil?
		  return sm.sku_mapable
		end
		return nil
	end

  # delete old auto generated mappings and create new auto mappings for a given product / variant / sub_variant
	def self.auto_generate(o)
    o.sku_mappings.where(:source=>'auto').destroy_all

    if o.class == 'product'
      SkuMapping.create(:sku=>o.base_sku, :sku_mapable_type=>o.class.to_s, sku_mapable_id=>o.id, :source=>'auto')
    elsif o.class == 'variant'
	    p = o.product
	    if !p.base_sku.nil? && !o.color1_code.nil?
		    if !o.size.nil? && o.size.length>=2
			    SkuMapping.create(:sku=>"#{p.base_sku}-#{o.color1_code}-#{o.size[0,2]}", :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')
			    SkuMapping.create(:sku=>"#{p.base_sku}-#{o.color1_code.gsub(/\//,'')}-#{o.size[0,2]}", :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')
			    SkuMapping.create(:sku=>"#{p.base_sku}-#{o.color1_code}-#{o.size[0,2]}", :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')
		    end
		    SkuMapping.create(:sku=>"#{p.base_sku}-#{o.color1_code}", :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')
		    SkuMapping.create(:sku=>"#{p.base_sku}-#{o.color1_code.gsub(/\//,'-')}", :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')
	    end
    elsif o.class == 'sub_variant'
      last_two = o.sku[-2,2]
    	if last_two == '.0'
    	  SkuMapping.create(:sku=>o.sku[0,o.sku.length-3], :sku_mapable_type=>o.class.to_s, :sku_mapable_id=>o.id, :source=>'auto')
    	end
    end
  end
    
  
end
