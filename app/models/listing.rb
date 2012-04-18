require 'amazon/mws'
class Listing < ActiveRecord::Base
  belongs_to :store
  belongs_to :product
  belongs_to :mws_request
  validates_uniqueness_of :product_id, :handle, :foreign_id, :scope => [:store_id], :allow_nil=>true
  validates_associated :store, :product
  
  default_scope where(:inactive_timestamp => nil)
  
  # listing cannot be destroyed - instead it is merely inactivated
  def inactivate
    self.inactive_timestamp = Time.now
    self.save
  end
  
end
