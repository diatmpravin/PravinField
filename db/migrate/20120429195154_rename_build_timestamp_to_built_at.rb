class RenameBuildTimestampToBuiltAt < ActiveRecord::Migration
  def change
    rename_column :listings, :build_timestamp, :built_at
    add_column :listings, :parent_listing_id, :integer
  end
end
