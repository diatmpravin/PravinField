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
  
  # an inactive listing means that an item was listed and removed
  # listings that have never been synced can be deleted
  # feed size limit 30,000 rows
  # RecommendedBrowseNode 60583031 60576021 for listing in Europe
  
  # 15 feeds before throttling, restore 1 request per 2 minutes
  # 10,000 requests per hour
  
  # feed request quota 10 requests
  # feed requet 
end
