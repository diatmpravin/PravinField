class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.integer :product_id
      t.integer :store_id
      t.string :handle
      t.string :foreign_id
      t.integer :mws_request_id

      t.timestamps
    end
  end
end
