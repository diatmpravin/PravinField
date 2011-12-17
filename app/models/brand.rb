class Brand < ActiveRecord::Base
	belongs_to :vendor
	has_many :products, :dependent => :destroy
	has_attached_file :icon, PAPERCLIP_STORAGE_OPTIONS
	
	validates_uniqueness_of :name
	validates_numericality_of :default_markup, { :only_integer => false, :greater_than => 0 }

	def process_from_vendor
		v = self.vendor
		v.login
		v.process_brand(self)
	end

end
