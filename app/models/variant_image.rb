require 'open-uri'

class VariantImage < ActiveRecord::Base
	belongs_to :variant
	has_attached_file :image, PAPERCLIP_STORAGE_OPTIONS.merge({:styles => { :thumb => "x30" }})
	validates_uniqueness_of :unique_image_file_name, :scope => [:variant_id]
	before_validation :download_remote_image
	after_post_process :set_image_dimensions

	def self.reprocess_all
		VariantImage.all.each do |vi|
			vi.image.reprocess! if vi.image
		end
	end

  protected
  def download_remote_image
    if self.image_file_name.nil? && !self.unique_image_file_name.nil?
      io = open(URI.parse(self.unique_image_file_name))
      def io.original_filename; base_uri.path.split('/').last; end
      self.image = io.original_filename.blank? ? nil : io
    end
  rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...) 
  end

	def set_image_dimensions
		if !self.image_width.is_a?(Numeric) || !self.image_file_name.nil?	  
		  if !image.queued_for_write[:original].nil?
		    geo = Paperclip::Geometry.from_file(image.queued_for_write[:original])
		    self.image_width = geo.width
		    self.image_height = geo.height
		  end
		end
	end
	
end
