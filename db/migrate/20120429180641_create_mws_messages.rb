class CreateMwsMessages < ActiveRecord::Migration
  def change
    create_table :mws_messages do |t|
      t.integer :listing_id
      t.text :message
      t.integer :matchable_id
      t.string :matchable_type

      t.timestamps
    end
  end
end
