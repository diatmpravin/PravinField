require 'open-uri'

class VariantImage < ActiveRecord::Base
	belongs_to :variant
	has_many :mws_messages
	has_attached_file :image, PAPERCLIP_STORAGE_OPTIONS.merge({:styles => { :thumb => "x30" }})
	has_attached_file :image2, PAPERCLIP_STORAGE_OPTIONS2.merge({:styles => { :thumb => "x30" }})
  before_validation :ignore_blanks_and_duplicates, :on => :create
	before_validation :upload_image_from_uri
	validates_uniqueness_of :unique_image_file_name, :scope => [:variant_id]
	after_post_process :set_image_dimensions
	
	def self.reprocess_all
		VariantImage.all.each do |vi|
			vi.image.reprocess! if vi.image
		end
	end

  protected
  
  # Happening before validation to avoid pulling invalid/duplicate URLs for no reason
  def ignore_blanks_and_duplicates
    if (self.image_file_name.nil? || self.image_file_name.blank?) && (self.unique_image_file_name.nil? || self.unique_image_file_name.blank?)
      self.errors[:unique_image_file_name].push 'cannot be blank unless uploading from a browser'
      return false
    end
    
    master = self.variant.product.master
    if !master.nil?
      master.variant_images.each do |i|
        if i.unique_image_file_name==self.unique_image_file_name      
          self.errors[:unique_image_file_name].push 'is a duplicate with a master image'
          return false
        end
      end
    end
  end
  
  # Open an io stream from a remote URL, and confirm the original file name is not blank
  def open_io_uri(url)
    io = open(url)
    def io.original_filename; base_uri.path.split('/').last; end
    return io unless io.original_filename.blank?
    self.errors[:unique_image_file_name].push 'does not link to a file'
    return nil
  end
  
  # Open an io stream from a local file, and confirm the original file name is not blank
  def open_io_file(path)
    io = open(path)
    def io.original_filename; path.split('/').last; end
    return io unless io.original_filename.blank?
    return nil
  end
  
  # Upload an image from either a remote URI or a local file
  def upload_image_from_uri
    if self.image_file_name.nil? && !self.unique_image_file_name.nil?
      uri = URI.parse(self.unique_image_file_name)
      self.image = open_io_uri(uri)
      self.image2 = open_io_uri(uri)
    end
  rescue TypeError
    self.image = open_io_file(self.unique_image_file_name)
    self.image2 = open_io_file(self.unique_image_file_name)
  rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...) 
    self.errors[:unique_image_file_name].push "returned #{$!.inspect}"
  end
  
  # Paperclip post processing callback to set the width and height of the image after it is loaded
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
