class AddFieldsToMwsMessages < ActiveRecord::Migration
  def change
    add_column :mws_messages, :result_code, :string
    add_column :mws_messages, :message_code, :string
    add_column :mws_messages, :result_description, :text
    
    add_column :mws_requests, :feed_submission_id, :string
    add_column :mws_requests, :processing_status, :string
    add_column :mws_requests, :submitted_at, :datetime
    add_column :mws_requests, :started_at, :datetime
    add_column :mws_requests, :completed_at, :datetime
  end
end
