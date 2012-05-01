require 'open-uri'

class VariantImage < ActiveRecord::Base
	belongs_to :variant
	has_many :mws_messages
	has_attached_file :image, PAPERCLIP_STORAGE_OPTIONS.merge({:styles => { :thumb => "x30" }})
	has_attached_file :image2, PAPERCLIP_STORAGE_OPTIONS2.merge({:styles => { :thumb => "x30" }})
  #TODO before_validation :ignore_duplicate_images
	before_validation :download_remote_image
	validates_uniqueness_of :unique_image_file_name, :scope => [:variant_id]
	after_post_process :set_image_dimensions
	
	def self.reprocess_all
		VariantImage.all.each do |vi|
			vi.image.reprocess! if vi.image
		end
	end

  protected
  
  def ignore_duplicate_images
    if !self.unique_image_file_name.nil? && !self.unique_image_file_name.blank?
      master_variant = self.variant.product.master_variant
      self.variant.product.master_variant.variant_images.each do |i|
        if i.unique_image_file_name==self.unique_image_file_name
          self.unique_image_file_name = nil
        end 
      end
    end
  end
  
  def open_io(url)
    io = open(url)
    def io.original_filename; base_uri.path.split('/').last; end
    if io.original_filename.blank?
      return nil
    end
    return io
  end
  
  def download_remote_image
    if self.image_file_name.nil? && !self.unique_image_file_name.nil?
      url = URI.parse(self.unique_image_file_name)
      self.image = open_io(url)
      self.image2 = open_io(url)
    end
  rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...) 
    puts $!
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
