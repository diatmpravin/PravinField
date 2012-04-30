class MwsMessage < ActiveRecord::Base
  attr_accessible :listing_id, :matchable_id, :matchable_type, :message, :variant_image_id, :feed_type
  belongs_to :matchable, :polymorphic => true
  belongs_to :listing
  belongs_to :variant_image
  serialize :message
  validates_uniqueness_of :matchable_id, :scope => [:listing_id, :matchable_type, :variant_image_id, :feed_type]
  validates_presence_of :feed_type, :listing_id, :matchable_type, :matchable_id
end
