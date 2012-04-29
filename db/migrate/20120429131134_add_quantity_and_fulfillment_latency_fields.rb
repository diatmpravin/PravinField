class AddQuantityAndFulfillmentLatencyFields < ActiveRecord::Migration
  def change
    add_column :brands, :fulfillment_latency, :integer
    add_column :sub_variants, :fulfillment_latency, :integer
    add_column :sub_variants, :quantity, :integer
  end
end
