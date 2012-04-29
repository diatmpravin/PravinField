class MwsRequest < ActiveRecord::Base
	belongs_to :store
	has_many :mws_responses, :dependent => :destroy
	has_many :mws_orders, :through => :mws_responses
	has_many :sub_requests, :class_name => "MwsRequest"
  belongs_to :parent_request, :class_name => "MwsRequest", :foreign_key => "mws_request_id"

	MAX_FAILURE_COUNT = 2
	ORDER_FAIL_WAIT = 60  

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

  # accepts a working MWS connection and a ListOrdersResponse, and fully processes these orders
  # calls the Amazon MWS API
  def process_orders(mws_connection, response)
    #puts "  PROCESS_ORDERS: response type #{response.class.to_s}, request type #{self.request_type}"
		next_token = process_response(mws_connection, response,0,0)
		if next_token.is_a?(Numeric)
			return next_token
		end
		
		page_num = 1
		failure_count = 0
		while next_token.is_a?(String) && page_num<self.store.max_order_pages do
		  #puts "  PROCESS_ORDERS: back, next_token present, getting orders list by next token"
			response = mws_connection.get_orders_list_by_next_token(:next_token => next_token)
		  #puts "  PROCESS_ORDERS: got orders by next token, going to process_response"
			n = process_response(mws_connection,response,page_num,ORDER_FAIL_WAIT)
			if n.is_a?(Numeric)
				failure_count += 1
				if failure_count >= MAX_FAILURE_COUNT
					return n
				end
			else
				page_num += 1
				next_token = n
			end
		end
		#puts "  PROCESS_ORDERS: finishing"   
  end
	
	# accepts a working MWS connection and the XML model of the response, and incorporates this information into the database
	# calls process_order or process_order_item in turn, which call the Amazon MWS API
	def process_response(mws_connection,response_xml,page_num,sleep_if_error)

    #puts "PROCESS_RESPONSE: request_type is #{self.request_type}"
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
		
		# If there is an error code, save the error in the record, sleep for some time to recover, and return the response id, indicating error
		if response_xml.accessors.include?("code")
		  #puts "PROCESS_RESPONSE: error code #{response_xml.message}"
			response.error_code = response_xml.code
			response.error_message = response_xml.message
			response.save!
			sleep sleep_if_error
			return response.id
		end
		#puts "no error code"
		
		# assign next token if given
		response.next_token = response_xml.next_token

    # if this is a response containing orders
		if self.request_type=="ListOrders"
			response.last_updated_before = response_xml.last_updated_before
			response.save!
			
			#puts "    PROCESS_RESPONSE: ListOrders response contains #{response_xml.orders.count} orders"

			# Process all orders first
			amazon_orders = Array.new
			response_xml.orders.each do |o|
			  amz_order = MwsOrder.find_by_amazon_order_id(o.amazon_order_id)
				if amz_order.nil?
				  amz_order = MwsOrder.create(:amazon_order_id => o.amazon_order_id, :mws_response_id=>response.id, :store_id=>self.store_id, :purchase_date=>o.purchase_date)
					#puts "      PROCESS_RESPONSE: new order #{amz_order.amazon_order_id} created, id:#{amz_order.id}, adding to array"
				else
					#puts "      PROCESS_RESPONSE: existing order #{amz_order.amazon_order_id} being updated, id:#{amz_order.id}, adding to array"
				end
				h = o.as_hash
				h[:mws_response_id] = response.id #TODO creating an orphan mws_response object by changing the response pointer
				amz_order.update_attributes(h)
				amazon_orders << amz_order
				#puts "      PROCESS_RESPONSE: now #{amazon_orders.count} orders in array"
			end
			
			#puts "    PROCESS_RESPONSE: done building array, #{amazon_orders.count} orders"
			# Then get item detail behind each order
			sleep_time = MwsOrder::get_sleep_time_per_order(amazon_orders.count)
			amazon_orders.each do |amz_order|
				sleep sleep_time
				#puts "      PROCESS_RESPONSE: going to process order #{amz_order.amazon_order_id}"
				r = amz_order.process_order(mws_connection)
			end
			
		# else if this is a response containing items
		elsif self.request_type=="ListOrderItems"
			response.amazon_order_id = response_xml.amazon_order_id
			response.save!
			
			#puts "            PROCESS_RESPONSE: ListOrderItems response contains #{response_xml.order_items.count} items"
						
			amz_order = MwsOrder.find_by_amazon_order_id(response.amazon_order_id)
			if !amz_order.nil?
			  response_xml.order_items.each do |i|
			    #puts "            PROCESS_RESPONSE: going to process item"
				  amz_order.process_order_item(i,response.id)
			  end
			  #puts "            PROCESS_RESPONSE: finished processing #{response_xml.order_items.count} items"
			end
		end
		#puts "PROCESS_RESPONSE: finished, returning next token or error code"
		return response.next_token
	end

	#def get_last_date
	#	self.mws_responses.order('last_updated_before DESC').first.last_updated_before
	#end

  #TODO
  def validate_feed
    #document_path, schema_path,root_element
    #schema = Nokogiri::XML::Schema(File.open('test/fixtures/xsd/Product.xsd'))
    #document = Nokogiri::XML(File.read(document_path))
    #schema.validate(document.xpath("//#{root_element}").to_s)
  
    #validate('input.xml', 'schema.xdf', 'container').each do |error|
    #  puts error.message
    #end
  end
	
	private
	
	def send_request
    if self.request_type=='SubmitFeed'
      response = self.store.mws_connection.submit_feed(self.feed_type,'Product',self.message)
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