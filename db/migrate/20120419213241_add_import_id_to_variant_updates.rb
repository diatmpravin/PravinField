class AddImportIdToVariantUpdates < ActiveRecord::Migration
  def change
    add_column :variant_updates, :import_id, :integer
  end
end
