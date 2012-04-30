#require 'amazon/mws'
class Listing < ActiveRecord::Base
  belongs_to :store
  belongs_to :product
  belongs_to :mws_request
  has_many :mws_messages
  
  #has_many :sub_listings, :class_name => "Listing"
  #belongs_to :parent_listing, :class_name => "Listing", :foreign_key => "parent_listing_id"  
  
  attr_accessible :product_id, :handle, :foreign_id, :store_id, :operation_type, :mws_request_id, :created_at, :status
  #validates_uniqueness_of :product_id, :handle, :foreign_id, :scope => [:store_id, :built_at], :allow_nil=>true
  validates_associated :store, :product
  
  # Associate this listing with a particular request
  # Build the messages necessary to render this message in the given request
  # Save this listing, and return messages for chaining
  def build_mws_messages(request)
    self.product.build_mws_messages(self, request.feed_type).flatten
  end
    
  #- we can search for products, variant, or subvariants that have been updated post their last listing
  
  #- A GetFeedSubmissionList is sent periodically
  #- Amazon returns if processing is complete or not
  #- if not complete, another GetFeedSubmissionList
  #- if it is complete, then send GetFeedSubmissionResult, which returns a processing report
  #- if processing report is error free, we are done
  # if it is not error free, must start all over again?
  
end
