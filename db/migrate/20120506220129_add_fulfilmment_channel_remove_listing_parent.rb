class AddFulfilmmentChannelRemoveListingParent < ActiveRecord::Migration
  def change
    add_column :products, :fulfillment_channel, :string
    remove_column :listings, :parent_listing_id
  end

end
