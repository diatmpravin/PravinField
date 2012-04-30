class AddVariantImageIdToMwsMessage < ActiveRecord::Migration
  def change
    add_column :mws_messages, :variant_image_id, :integer
    add_column :listings, :operation_type, :string
    add_column :listings, :build_timestamp, :datetime
    remove_column :listings, :inactive_timestamp
  end
end
