class Brand < ActiveRecord::Base
	belongs_to :vendor
	has_many :products, :dependent => :destroy
	has_attached_file :icon, PAPERCLIP_STORAGE_OPTIONS.merge({:styles => { :thumb => "x30" }})
	
	validates_uniqueness_of :name
	validates_numericality_of :default_markup, { :only_integer => false, :greater_than => 0 }

	def revise_base_skus
		self.products.each do |p|
			if self.name == 'Juicy Couture' || self.name == 'Polo' || self.name == 'Ralph' || self.name == 'Dolce & Gabbana' || self.name == 'Ray-Ban'
				p.base_sku = p.base_sku[1,p.base_sku.length-1]
				p.save
			end
		end
	end
	
	def revise_variant_skus
		self.products.each do |p|			
			p.variants.each do |v|
				v.sku = v.get_clean_sku
				v.save
			end
		end
	end

	def process_from_vendor
		v = self.vendor
		v.login
		v.process_brand(self)
	end

	def add_listings(store)
		store.add_listings(self.products)
	end

	def remove_listings(store)
    store.remove_listings(self.products)
	end

end
