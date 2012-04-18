class MwsRequest < ActiveRecord::Base
	belongs_to :store
	has_many :mws_responses, :dependent => :destroy
	has_many :mws_orders, :through => :mws_responses
	has_many :sub_requests, :class_name => "MwsRequest"
  belongs_to :parent_request, :class_name => "MwsRequest", :foreign_key => "mws_request_id"
  
  #TODO implement code to send request
  after_create :send_request

	def get_request_summary_string
		error_count = get_responses_with_errors.count
		order_count = self.mws_orders.count
		orders_missing_items_count = get_orders_missing_items.count
		if error_count > 0 || orders_missing_items_count >0
			return "ERROR: #{error_count} errors, #{self.mws_responses.count} response pages, #{order_count} orders, #{orders_missing_items_count} without items"
		else
			return "OK: #{order_count} orders"
		end
	end
  
  # return orders that either have 0 quantity ordered, or fewer items loaded than ordered
	def get_orders_missing_items
		orders_missing_items = Array.new
		self.mws_orders.each do |o|
			if o.get_item_quantity_missing > 0 || o.get_item_quantity_ordered == 0
				orders_missing_items << o
			end
		end
		return orders_missing_items
	end

	def get_responses_with_errors
		error_responses = Array.new
		self.sub_requests.each do |r|
			error_responses = error_responses + r.mws_responses.where('error_message IS NOT NULL')
		end			
		return error_responses
	end
	
	def process_response(mws_connection,response_xml,page_num,sleep_if_error)

		# Update the request_id in our request parent object if not set already
		if self.amazon_request_id.nil?
			self.amazon_request_id = response_xml.request_id
			self.save!
		end		

		# Create a new response object, link to the initial request
		response = MwsResponse.new(
			:request_type => self.request_type,
			:mws_request_id => self.id, 
			:amazon_request_id => response_xml.request_id,
			:page_num => page_num
		)
		
		if response_xml.accessors.include?("code")
			response.error_code = response_xml.code
			response.error_message = response_xml.message
			response.save!
			sleep sleep_if_error
			return response.id
		end
			
		response.next_token = response_xml.next_token
	
		if self.request_type=="ListOrders"
			response.last_updated_before = response_xml.last_updated_before
			response.save!

			# Process all orders first
			#shipping_update = 0
			amazon_orders = Array.new
			response_xml.orders.each do |o|
				h = MwsHelper.instance_vars_to_hash(o)
				amz_order = MwsOrder.find_by_amazon_order_id(o.amazon_order_id)
				#if !amz_order.nil? && amz_order.number_of_items_unshipped>0 && h['number_of_items_unshipped'] == 0 
				#	amz_order.set_shipped
				#	shipping_update = 1 # this is likely just a 'shipped' update, so don't pull new items
				#else
					amz_order = MwsOrder.create(:amazon_order_id => o.amazon_order_id)
				#end
				h = MwsHelper.instance_vars_to_hash(o)
				h[:mws_response_id] = response.id
				h[:store_id] = self.store_id
				amz_order.update_attributes(h)
				#if shipping_update == 0
				amazon_orders << amz_order
				#end
			end
			
			# Then loop back to get item detail behind each order
			sleep_time = MwsOrder::get_sleep_time_per_order(amazon_orders.count)
			amazon_orders.each do |amz_order|
				sleep sleep_time
				r = amz_order.process_order(mws_connection)
			end
		elsif self.request_type=="ListOrderItems"
			response.amazon_order_id = response_xml.amazon_order_id
			response.save!
			amz_order = MwsOrder.find_by_amazon_order_id(response.amazon_order_id)
			response_xml.order_items.each do |i|
				amz_order.process_order_item(i,response.id)
			end
		end
		return response.next_token
	end

	def get_last_date
		self.mws_responses.order('last_updated_before DESC').first.last_updated_before
	end
	
	private

  #   FEED_TYPES = {
  #      :product_data              => '_POST_PRODUCT_DATA_',
  #      :product_relationship_data => '_POST_PRODUCT_RELATIONSHIP_DATA_',
  #      :item_data                 => '_POST_ITEM_DATA_',
  #      :product_overrides         => '_POST_PRODUCT_OVERRIDES_DATA_',
  #      :product_image_data        => '_POST_PRODUCT_IMAGE_DATA_',
  #      :product_pricing           => '_POST_PRODUCT_PRICING_DATA_',
  #      :inventory_availability    => '_POST_INVENTORY_AVAILABILITY_DATA_',
  #      :order_acknowledgement     => '_POST_ORDER_ACKNOWLEDGEMENT_DATA_',
  #      :order_fulfillment         => '_POST_ORDER_FULFILLMENT_DATA_',
  #      :payment_adjustment        => '_POST_PAYMENT_ADJUSTMENT_DATA_',
	
	def send_request
    if self.request_type=='SubmitFeed'
      if self.feed_type==:product_data
        response = self.store.mws_connection.submit_feed(:product_data,'Product',self.message)
        #puts response.inspect
        MwsResponse.create(
			    :request_type => self.request_type,
			    :mws_request_id => self.id, 
			    :amazon_request_id => response.request_id,
			    :feed_submission_id => response.feed_submission.id,
			    :processing_status => response.feed_submission.feed_processing_status
		    )
		    
		    #TODO begin process to poll status periodically, creating a sub request each time, and a response each time
		  end
		end
	end
	
end