class Brand < ActiveRecord::Base
	belongs_to :vendor
	has_many :products, :dependent => :destroy
	has_many :variants, :through => :products
	has_many :sku_patterns
	
	has_attached_file :icon, PAPERCLIP_STORAGE_OPTIONS.merge({:styles => { :normal => "170x", :thumb => "x30" }})
	validates_uniqueness_of :name
	validates_numericality_of :default_markup, { :only_integer => false, :greater_than => 0 }
		
	def revise_variant_skus
		self.variants.each do |v|
		  v.sku = v.get_clean_sku
			v.save
		end
	end

end
