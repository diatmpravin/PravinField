class MwsMessage < ActiveRecord::Base
  attr_accessible :listing_id, :matchable_id, :matchable_type, :message, :variant_image_id, :feed_type, :result_code, :message_code, :result_description
  belongs_to :matchable, :polymorphic => true
  belongs_to :listing
  belongs_to :variant_image
  serialize :message
  validates_presence_of :feed_type, :listing_id, :matchable_type, :matchable_id
  
  def get_xml
    Amazon::MWS::FeedBuilder.new(self.listing.mws_request.message_type,[self.message],{:merchant_id => 'DUMMY'}).render
  end
  
end
