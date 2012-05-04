#require 'amazon/mws'
class Listing < ActiveRecord::Base
  belongs_to :store
  belongs_to :product
  belongs_to :mws_request
  has_many :mws_messages 
  
  attr_accessible :product_id, :handle, :foreign_id, :store_id, :operation_type, :mws_request_id, :created_at, :status
  #validates_uniqueness_of :product_id, :handle, :foreign_id, :scope => [:store_id, :built_at], :allow_nil=>true
  
  before_validation :clean_status_and_op_type, :on => :create
  validates_presence_of :store_id, :product_id
  validates_associated :store, :product
  validates_inclusion_of :operation_type, :in => %w(Update Delete)
  
  # queued = listing has been created, but not processed or assigned to a request
  # assigned = listing has been assigned to a request and is being processed
  # error = listing is finished, but some messages had errors, and thus it needs to be fixed and run again
  # deleted = delete listing was successful
  # updated = prior update listing (formerly active) now changed to updated to reflect a newer update listing
  # removed = prior update listing (formerly active) now changed to removed to reflect a newer delete listing
  # active = update listing was successful

  validates_inclusion_of :status, :in => %w(queued assigned error deleted removed updated active)

	#state_machine :state, :initial=>:queued do
	#  event :assign do transition :queued => :assigned end 
	#  event :submit_feed do
	#    transition :assigned => :product_submitted
	#    transition :product_done => :relationship_submitted
	#    transition :relationship_done => :price_submitted
	#    transition :price_done => :image_submitted
	#    transition :image_done => :inventory_submitted
	#  end
	#  event :feed_done do
	#    transition :product_submitted => :product_done
	#    transition :relationship_submitted => :relationship_done
	#    transition :price_submitted => :price_done
	#    transition :image_submitted => :image_done
	#    transition :inventory_submitted => :done
	#  end
	#	after_transition any => :done, :do => :determine_status
	#end

  # Set the status of this listing to assigned, and register the mws_request id
  # Return the messages necessary to render this message in the given request
  def assign_amazon!(request)
    self.update_attributes!(:mws_request_id => request.id, :status => 'assigned')
    return self.build_mws_messages(request)
  end

  # Update status for listing to assigned
  # Process this listing immediately
  # TODO update listing if error
  def process_shopify!(request)
  	raise "Shopify store missing authenticated URL" if self.store.authenticated_url.nil?
    ShopifyAPI::Base.site = self.store.authenticated_url
    
    self.update_attributes!(:mws_request_id => request.id, :status => 'assigned')
	  
    # Get existing active Shopify listings (for update and delete), should only return 1
	  active_listings = self.product.active_listings.where(:store_id=>self.store_id)  		  
    
	  if self.operation_type == 'Update'
	    #TODO error handling
	    # if Shopify product already exists, update it
	    if active_listings.any?
	      shopify_product = ShopifyAPI::Product.find(active_listings.last.foreign_id)
	      shopify_product.update_attributes(self.product.attributes_for_shopify)
	      self.update_status!
	    else # else create it
	      shopify_product = ShopifyAPI::Product.create(self.product.attributes_for_shopify)
	      self.update_attributes(:handle=>shopify_product.handle, :foreign_id=>shopify_product.id)
	      self.update_status!
      end

    elsif self.operation_type == 'Delete'
	    if active_listings.any?
	      shopify_product = ShopifyAPI::Product.find(active_listings.last.foreign_id)
	      shopify_product.destroy        
      else
        raise "Delete listing with no active listing"
      end
    end
    self.update_status!
  end
  
  def build_mws_messages(request)
    self.product.build_mws_messages(self, request.feed_type).flatten    
  end
  
  # TODO search for products, variant, or subvariants that have been updated post their last listing
    
  # set status to complete unless there were errors, to be called after the request feed submission process completes  
  def update_status!
    if self.get_mws_errors.any?
      self.update_attributes!(:status => 'error')
    elsif self.operation_type == 'Delete'
      self.remove_active!
    else
      self.update_active!
    end
  end
  
  # return messages that contain errors pertaining to this listing
  def get_mws_errors
    return self.mws_messages.where(:result_code=>'Error')
  end
    
  protected
  
  def update_active!
    self.product.active_listings.each do |l|
      l.update_attributes(:status=>'updated')
    end
    self.update_attributes!(:status => 'active')
  end
  
  def remove_active!
    self.product.active_listings.each do |l|
      l.update_attributes(:status=>'removed')
    end
    self.update_attributes(:status=>'deleted')
  end

  # TODO replace this with a default
  def clean_status_and_op_type
    self.operation_type = 'Update' unless self.operation_type == 'Delete'
    self.status = 'queued'
  end
  
end
