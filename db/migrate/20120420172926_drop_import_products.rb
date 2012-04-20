class DropImportProducts < ActiveRecord::Migration
  def change
    drop_table :import_products
  end
end
