class RemoveActiveFromListings < ActiveRecord::Migration
  def change
    remove_column :listings, :active
  end
end
