class Vendor < ActiveRecord::Base
	has_many :brands, :dependent => :destroy
	has_many :products, :through => :brands
	has_attached_file :icon, PAPERCLIP_STORAGE_OPTIONS.merge({:styles => { :normal => "170x", :thumb => "x30" }})

  before_validation :nil_if_blank
  
	validates :name, :presence=>true, :uniqueness=>true
	
	SEARCH_FIELDS = [ 'name', 'base_url', 'login_url' ] 
	
	# Remove all products (permanently) from each brand under this vendor (presumably in prep for a new scrape)
	def clear_products
		self.brands.each do |b|
			b.products.each do |p| 
				p.destroy
			end
		end
	end
	
	protected

  def nil_if_blank
    SEARCH_FIELDS.each { |attr| self[attr] = nil if self[attr].blank? }
  end	
	
end
