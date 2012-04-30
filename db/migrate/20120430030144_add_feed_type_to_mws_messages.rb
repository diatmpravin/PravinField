class AddFeedTypeToMwsMessages < ActiveRecord::Migration
  def change
    add_column :mws_messages, :feed_type, :string
  end
end
