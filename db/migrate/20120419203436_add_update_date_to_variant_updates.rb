class AddUpdateDateToVariantUpdates < ActiveRecord::Migration
  def change
    add_column :variant_updates, :update_date, :datetime
  end
end
