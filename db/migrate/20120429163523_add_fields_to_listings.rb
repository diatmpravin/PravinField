class AddFieldsToListings < ActiveRecord::Migration
  def change
    add_column :listings, :status, :string
    add_column :mws_requests, :message_type, :string
  end
end
